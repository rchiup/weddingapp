import { randomUUID } from "node:crypto";
import type { QueryDocumentSnapshot } from "firebase-admin/firestore";
import { getAdminDb } from "@/lib/firebase/admin";
import { mockAnnouncements, mockInvites, mockWeddings } from "@/lib/store/mock";
import type { Announcement, Invite, RSVPStatus, Wedding } from "@/types/domain";
import { normalizeInviteFromStorage } from "@/lib/store/invite-normalize";

const weddings = [...mockWeddings];
const invites = [...mockInvites];
const announcements = [...mockAnnouncements];

function mapsLinksFor(wedding: Wedding) {
  const { lat, lng } = wedding.location;
  return {
    googleMapsUrl: `https://www.google.com/maps/search/?api=1&query=${lat},${lng}`,
    wazeUrl: `https://waze.com/ul?ll=${lat},${lng}&navigate=yes`
  };
}

export async function getWeddingBySlug(slug: string) {
  const db = getAdminDb();
  if (!db) {
    const wedding = weddings.find((w) => w.slug === slug);
    if (!wedding) return null;
    return { ...wedding, mapsLinks: mapsLinksFor(wedding) };
  }

  const snap = await db.collection("weddings").where("slug", "==", slug).limit(1).get();
  if (snap.empty) return null;
  const doc = snap.docs[0];
  const wedding = doc.data() as Wedding;
  return { ...wedding, id: doc.id, mapsLinks: mapsLinksFor(wedding) };
}

export async function getWeddingById(weddingId: string) {
  const db = getAdminDb();
  if (!db) {
    const wedding = weddings.find((w) => w.id === weddingId);
    if (!wedding) return null;
    return { ...wedding, mapsLinks: mapsLinksFor(wedding) };
  }
  const doc = await db.collection("weddings").doc(weddingId).get();
  if (!doc.exists) return null;
  const wedding = doc.data() as Wedding;
  return { ...wedding, id: doc.id, mapsLinks: mapsLinksFor(wedding) };
}

export async function getInviteByToken(token: string) {
  const db = getAdminDb();
  if (!db) {
    const found = invites.find((i) => i.token === token) ?? null;
    return found ? normalizeInviteFromStorage(found, token) : null;
  }
  const doc = await db.collection("invites").doc(token).get();
  if (!doc.exists) return null;
  return normalizeInviteFromStorage(doc.data() as Invite, token);
}

export async function getGuestView(slug: string, token: string) {
  const [wedding, invite] = await Promise.all([getWeddingBySlug(slug), getInviteByToken(token)]);
  if (!wedding || !invite || invite.weddingId !== wedding.id) {
    return null;
  }
  const feed = await getAnnouncements(wedding.id);
  return { wedding, invite, announcements: feed };
}

export async function updateInviteRSVP(
  token: string,
  payload: { inviteStatus: RSVPStatus; dietaryRestrictions?: string }
) {
  const db = getAdminDb();
  if (!db) {
    const index = invites.findIndex((i) => i.token === token);
    if (index < 0) return null;
    invites[index] = {
      ...invites[index],
      inviteStatus: payload.inviteStatus,
      dietaryRestrictions: payload.dietaryRestrictions ?? invites[index].dietaryRestrictions,
      updatedAt: new Date().toISOString()
    };
    return invites[index];
  }

  const ref = db.collection("invites").doc(token);
  await ref.update({
    inviteStatus: payload.inviteStatus,
    dietaryRestrictions: payload.dietaryRestrictions ?? "",
    updatedAt: new Date().toISOString()
  });
  const after = await ref.get();
  return normalizeInviteFromStorage(after.data() as Invite, token);
}

export async function updatePlusOne(
  token: string,
  payload: {
    status: RSVPStatus;
    name?: string;
    dietaryRestrictions?: string;
  }
) {
  const db = getAdminDb();
  if (!db) {
    const index = invites.findIndex((i) => i.token === token);
    if (index < 0) return null;
    invites[index] = {
      ...invites[index],
      plusOne: {
        ...invites[index].plusOne,
        status: payload.status,
        name: payload.name ?? invites[index].plusOne.name ?? "",
        dietaryRestrictions: payload.dietaryRestrictions ?? invites[index].plusOne.dietaryRestrictions
      },
      updatedAt: new Date().toISOString()
    };
    return invites[index];
  }

  const ref = db.collection("invites").doc(token);
  const snap = await ref.get();
  const cur = snap.data() as Invite | undefined;
  const prevType = cur?.plusOne?.type;
  const type: Invite["plusOne"]["type"] =
    prevType === "open" || prevType === "nominal" || prevType === "none" ? prevType : "open";

  await ref.update({
    plusOne: {
      type,
      status: payload.status,
      name: payload.name ?? "",
      dietaryRestrictions: payload.dietaryRestrictions ?? ""
    },
    updatedAt: new Date().toISOString()
  });
  const after = await ref.get();
  return normalizeInviteFromStorage(after.data() as Invite, token);
}

export async function getAnnouncements(weddingId: string) {
  const db = getAdminDb();
  if (!db) {
    return announcements.filter((a) => a.weddingId === weddingId && a.active);
  }
  const snap = await db
    .collection("weddings")
    .doc(weddingId)
    .collection("announcements")
    .where("active", "==", true)
    .get();
  return snap.docs.map((d: QueryDocumentSnapshot) => ({
    id: d.id,
    ...(d.data() as Omit<Announcement, "id">)
  }));
}

export async function listWeddingInvites(weddingId: string) {
  const db = getAdminDb();
  if (!db) {
    return invites.filter((i) => i.weddingId === weddingId);
  }
  const snap = await db.collection("invites").where("weddingId", "==", weddingId).get();
  return snap.docs.map((d: QueryDocumentSnapshot) => d.data() as Invite);
}

export async function setTable(token: string, tableLabel: string) {
  const db = getAdminDb();
  if (!db) {
    const index = invites.findIndex((i) => i.token === token);
    if (index < 0) return null;
    invites[index] = {
      ...invites[index],
      tableLabel,
      updatedAt: new Date().toISOString()
    };
    return invites[index];
  }

  const ref = db.collection("invites").doc(token);
  await ref.update({ tableLabel, updatedAt: new Date().toISOString() });
  const after = await ref.get();
  return after.data() as Invite;
}

export async function createAnnouncement(weddingId: string, text: string, priority: "normal" | "high") {
  const db = getAdminDb();
  const now = new Date().toISOString();
  if (!db) {
    const item: Announcement = {
      id: randomUUID(),
      weddingId,
      text,
      priority,
      active: true,
      createdAt: now
    };
    announcements.unshift(item);
    return item;
  }
  const ref = await db.collection("weddings").doc(weddingId).collection("announcements").add({
    text,
    priority,
    active: true,
    createdAt: now
  });
  return { id: ref.id, weddingId, text, priority, active: true, createdAt: now };
}

export async function listWeddingsForAdmin(ownerEmail: string) {
  const db = getAdminDb();
  if (!db) {
    return weddings.filter((w) => w.ownerEmail === ownerEmail || ownerEmail === "novios@eventapp.com");
  }
  const snap = await db.collection("weddings").where("ownerEmail", "==", ownerEmail).get();
  return snap.docs.map((d: QueryDocumentSnapshot) => ({ ...(d.data() as Wedding), id: d.id }));
}
