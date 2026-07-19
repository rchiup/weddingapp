import { existsSync, readFileSync } from "node:fs";
import { resolve } from "node:path";
import { cert, getApp, getApps, initializeApp } from "firebase-admin/app";
import { getFirestore } from "firebase-admin/firestore";

type ServiceAccountJson = {
  project_id: string;
  client_email: string;
  private_key: string;
};

function loadServiceAccountFromPath(relativeOrAbsolute: string): ServiceAccountJson | null {
  const fullPath = resolve(process.cwd(), relativeOrAbsolute);
  if (!existsSync(fullPath)) {
    return null;
  }
  const raw = readFileSync(fullPath, "utf8");
  return JSON.parse(raw) as ServiceAccountJson;
}

function hasAdminEnvVars() {
  return Boolean(
    process.env.NEXT_PUBLIC_FIREBASE_PROJECT_ID &&
      process.env.FIREBASE_CLIENT_EMAIL &&
      process.env.FIREBASE_PRIVATE_KEY
  );
}

/**
 * Resuelve credenciales Admin en este orden:
 * 1) `FIREBASE_SERVICE_ACCOUNT_PATH` o `GOOGLE_APPLICATION_CREDENTIALS` → archivo JSON (recomendado en local)
 * 2) Variables `NEXT_PUBLIC_FIREBASE_PROJECT_ID` + `FIREBASE_CLIENT_EMAIL` + `FIREBASE_PRIVATE_KEY` (p. ej. Vercel)
 */
function getCredential() {
  const pathFromEnv =
    process.env.FIREBASE_SERVICE_ACCOUNT_PATH || process.env.GOOGLE_APPLICATION_CREDENTIALS;

  if (pathFromEnv) {
    const sa = loadServiceAccountFromPath(pathFromEnv);
    if (!sa) {
      return null;
    }
    return {
      credential: cert({
        projectId: sa.project_id,
        clientEmail: sa.client_email,
        privateKey: sa.private_key
      }),
      projectId: sa.project_id
    };
  }

  if (hasAdminEnvVars()) {
    return {
      credential: cert({
        projectId: process.env.NEXT_PUBLIC_FIREBASE_PROJECT_ID!,
        clientEmail: process.env.FIREBASE_CLIENT_EMAIL!,
        privateKey: process.env.FIREBASE_PRIVATE_KEY!.replace(/\\n/g, "\n")
      }),
      projectId: process.env.NEXT_PUBLIC_FIREBASE_PROJECT_ID!
    };
  }

  return null;
}

export function getAdminDb() {
  const cred = getCredential();
  if (!cred) {
    return null;
  }

  const app =
    getApps().length > 0
      ? getApp()
      : initializeApp({
          credential: cred.credential,
          projectId: cred.projectId
        });

  return getFirestore(app);
}
