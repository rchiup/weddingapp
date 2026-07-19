/**
 * Carga datos demo en Firestore (Release 1).
 * Requiere credenciales Admin: FIREBASE_SERVICE_ACCOUNT_PATH o variables en .env.local
 *
 * Uso: npm run seed
 */
import { config } from "dotenv";
import { resolve } from "node:path";

config({ path: resolve(process.cwd(), ".env.local") });
config({ path: resolve(process.cwd(), ".env") });

const WEDDING_ID = "w_001";

const weddingPayload = {
  slug: "matias-cata",
  name: "Matrimonio Matias & Catalina",
  dateTime: "2026-12-12T19:00:00.000Z",
  welcomeMessage: "Nos encantaria compartir este dia contigo.",
  locationText: "Centro de Eventos El Bosque, Las Condes, Santiago",
  location: {
    lat: -33.4123,
    lng: -70.5678
  },
  dressCode:
    "Etiqueta rigurosa. Traje oscuro o smoking; vestido largo. Tonos claros opcionales para la mujer.",
  giftListUrl: "https://example.com/regalos",
  ownerEmail: "novios@eventapp.com"
};

const invites: Record<
  string,
  {
    token: string;
    weddingId: string;
    guestName: string;
    guestPhone?: string;
    inviteStatus: "pending" | "confirmed" | "rejected";
    dietaryRestrictions?: string;
    tableLabel?: string;
    plusOne: {
      type: "none" | "open" | "nominal";
      name?: string;
      status: "pending" | "confirmed" | "rejected" | "not_applicable";
      dietaryRestrictions?: string;
    };
    updatedAt: string;
  }
> = {
  inv_mn_001: {
    token: "inv_mn_001",
    weddingId: WEDDING_ID,
    guestName: "Matias Navarrete",
    guestPhone: "+56912345678",
    inviteStatus: "pending",
    dietaryRestrictions: "",
    tableLabel: "Mesa 12",
    plusOne: {
      type: "open",
      status: "pending",
      name: ""
    },
    updatedAt: new Date().toISOString()
  },
  inv_cp_002: {
    token: "inv_cp_002",
    weddingId: WEDDING_ID,
    guestName: "Catalina Perez",
    guestPhone: "+56987654321",
    inviteStatus: "confirmed",
    tableLabel: "Mesa 8",
    plusOne: {
      type: "nominal",
      status: "confirmed",
      name: "Felipe Soto"
    },
    updatedAt: new Date().toISOString()
  }
};

const announcements: Array<{ id: string; text: string; priority: "normal" | "high" }> = [
  {
    id: "a_1",
    text: "La ceremonia comienza puntual a las 19:00.",
    priority: "high"
  },
  {
    id: "a_2",
    text: "Habra transporte de regreso a las 02:00.",
    priority: "normal"
  }
];

async function main() {
  const { getAdminDb } = await import("../lib/firebase/admin");
  const db = getAdminDb();

  if (!db) {
    console.error(
      "[seed] No hay credenciales de Firebase Admin. Configura en .env.local:\n" +
        "  FIREBASE_SERVICE_ACCOUNT_PATH=./weddingapp-local-firebase-adminsdk-....json\n" +
        "  (o GOOGLE_APPLICATION_CREDENTIALS con la misma ruta)\n" +
        "  o bien NEXT_PUBLIC_FIREBASE_PROJECT_ID + FIREBASE_CLIENT_EMAIL + FIREBASE_PRIVATE_KEY"
    );
    process.exit(1);
  }

  const batch = db.batch();

  const weddingRef = db.collection("weddings").doc(WEDDING_ID);
  batch.set(weddingRef, weddingPayload, { merge: true });

  for (const data of Object.values(invites)) {
    const ref = db.collection("invites").doc(data.token);
    batch.set(ref, data, { merge: true });
  }

  const now = new Date().toISOString();
  for (const ann of announcements) {
    const ref = weddingRef.collection("announcements").doc(ann.id);
    batch.set(
      ref,
      {
        text: ann.text,
        priority: ann.priority,
        active: true,
        createdAt: now
      },
      { merge: true }
    );
  }

  await batch.commit();

  console.log("[seed] OK. Datos escritos en Firestore:");
  console.log(`  weddings/${WEDDING_ID} (slug: ${weddingPayload.slug})`);
  console.log(`  invites/${Object.keys(invites).join(", ")}`);
  console.log(`  weddings/${WEDDING_ID}/announcements/${announcements.map((a) => a.id).join(", ")}`);
  console.log("\nPrueba checklist: http://localhost:3000/matias-cata/inv_mn_001");
  console.log("RSVP: http://localhost:3000/matias-cata/inv_mn_001/invite");
}

main().catch((err) => {
  console.error("[seed] Error:", err);
  process.exit(1);
});
