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
export async function backend(path: string, init?: RequestInit) { const response = await fetch(`${BACKEND}${path}`, { ...init, headers: { "Content-Type": "application/json", ...(init?.headers || {}) } }); if (!response.ok) throw new Error(`Error ${response.status}`); return response.json(); }
