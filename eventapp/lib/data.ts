import { getFirebaseClientApp } from "@/lib/firebase/client";
import { addDoc, collection, doc, getDoc, getDocs, getFirestore, limit, orderBy, query, setDoc, where } from "firebase/firestore";

export const BACKEND = process.env.NEXT_PUBLIC_BACKEND_URL || "https://weddingapp-c6ix.onrender.com";
export type RecordData = Record<string, unknown> & { id: string };
const db = () => { const app = getFirebaseClientApp(); return app ? getFirestore(app) : null; };

export async function listEventCollection(eventId: string, name: string): Promise<RecordData[]> {
  const fire = db(); if (!fire || !eventId) return [];
  const snap = await getDocs(query(collection(fire, "events", eventId, name), limit(500)));
  return snap.docs.map((item) => ({ id: item.id, ...item.data() }));
}
export async function getEventDoc(eventId: string, name: string, id: string): Promise<RecordData | null> {
  const fire = db(); if (!fire) return null; const snap = await getDoc(doc(fire, "events", eventId, name, id)); return snap.exists() ? { id: snap.id, ...snap.data() } as RecordData : null;
}
export async function setEventDoc(eventId: string, name: string, id: string, data: Record<string, unknown>) {
  const fire = db(); if (!fire) throw new Error("Firebase no está configurado"); await setDoc(doc(fire, "events", eventId, name, id), data, { merge: true });
}
export async function addEventDoc(eventId: string, name: string, data: Record<string, unknown>) {
  const fire = db(); if (!fire) throw new Error("Firebase no está configurado"); await addDoc(collection(fire, "events", eventId, name), data);
}
export async function searchGuests(eventId: string, text: string) {
  const fire = db(); if (!fire) return []; const value = text.trim().toLowerCase();
  const q = value ? query(collection(fire, "events", eventId, "guests"), where("nameLower", ">=", value), where("nameLower", "<=", `${value}\uf8ff`), limit(20)) : query(collection(fire, "events", eventId, "guests"), limit(100));
  const snap = await getDocs(q); return snap.docs.map((item) => ({ id: item.id, ...item.data() }));
}
export async function listSongs(eventId: string) { const fire = db(); if (!fire) return []; try { const snap = await getDocs(query(collection(fire, "events", eventId, "songs"), orderBy("created_at", "desc"))); return snap.docs.map((x) => ({ id: x.id, ...x.data() })); } catch { return listEventCollection(eventId, "songs"); } }

export type ResolvedEvent = {
  eventId: string;
  eventName: string;
  eventDate: string;
  eventActive: boolean;
  settings: Record<string, unknown>;
};

function storedDate(value: unknown): string {
  if (!value) return "";
  if (typeof value === "string") return Number.isNaN(Date.parse(value)) ? "" : value;
  if (value instanceof Date) return value.toISOString();
  if (typeof value === "object" && value && "toDate" in value) {
    const converted = (value as { toDate: () => Date }).toDate();
    return converted.toISOString();
  }
  return "";
}

export async function resolveEventCode(rawCode: string): Promise<ResolvedEvent> {
  const normalized = rawCode.trim().toUpperCase();
  const eventCode = normalized.endsWith("-NOVIOS") ? normalized.slice(0, -7) : normalized;
  const fire = db();
  if (!fire) throw new Error("La conexión del evento no está configurada. Intenta nuevamente en unos minutos.");

  const codeSnapshot = await getDoc(doc(fire, "events_by_code", eventCode));
  const mappedId = codeSnapshot.exists() ? String(codeSnapshot.data().eventId || "") : "";
  const eventId = mappedId || eventCode;
  const [eventSnapshot, publicSnapshot] = await Promise.all([
    getDoc(doc(fire, "events", eventId)),
    getDoc(doc(fire, "events", eventId, "settings", "public")),
  ]);

  // Los eventos antiguos no tenían events_by_code ni documento padre, pero sí
  // settings/public. Esto permite migrarlos sin aceptar códigos inventados.
  if (!codeSnapshot.exists() && !eventSnapshot.exists() && !publicSnapshot.exists()) {
    throw new Error("Código de evento inválido. Revisa que esté escrito exactamente como te lo enviaron.");
  }

  const event = eventSnapshot.exists() ? eventSnapshot.data() : {};
  const publicSettings = publicSnapshot.exists() ? publicSnapshot.data() : {};
  const settings = {
    ...(typeof event.settings === "object" && event.settings ? event.settings : {}),
    ...publicSettings,
  };
  const coupleNames = String(publicSettings.coupleNames || "").trim();
  const storedName = String(event.name || "").trim();

  return {
    eventId,
    eventName: coupleNames || storedName || `Evento ${eventId}`,
    eventDate: storedDate(event.date),
    eventActive: event.active !== false,
    settings,
  };
}
async function responseJson(response: Response) {
  const data = await response.json().catch(() => ({}));
  if (!response.ok) {
    const message = typeof data?.error === "string" ? data.error : `Error ${response.status}`;
    throw new Error(message);
  }
  return data;
}

export async function backend(path: string, init?: RequestInit) {
  const response = await fetch(`${BACKEND}${path}`, {
    ...init,
    headers: { "Content-Type": "application/json", ...(init?.headers || {}) },
  });
  return responseJson(response);
}

export async function backendForm(path: string, form: FormData, init?: Omit<RequestInit, "body">) {
  const response = await fetch(`${BACKEND}${path}`, { ...init, method: init?.method || "POST", body: form });
  return responseJson(response);
}

export function backendUpload(path: string, form: FormData, onProgress: (progress: number) => void) {
  return new Promise<Record<string, unknown>>((resolve, reject) => {
    const request = new XMLHttpRequest();
    request.open("POST", `${BACKEND}${path}`);
    request.timeout = 90_000;
    request.upload.onprogress = (event) => {
      if (event.lengthComputable) onProgress(Math.round((event.loaded / event.total) * 100));
    };
    request.onerror = () => reject(new Error("No pudimos conectar con el servicio de fotos."));
    request.ontimeout = () => reject(new Error("La subida tardó demasiado. Revisa tu conexión e intenta nuevamente."));
    request.onload = () => {
      let data: Record<string, unknown> = {};
      try { data = JSON.parse(request.responseText || "{}"); } catch { /* respuesta no JSON */ }
      if (request.status >= 200 && request.status < 300) return resolve(data);
      reject(new Error(typeof data.error === "string" ? data.error : `Error ${request.status} al subir la foto`));
    };
    request.send(form);
  });
}
