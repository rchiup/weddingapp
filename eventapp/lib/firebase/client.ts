import { getApp, getApps, initializeApp } from "firebase/app";

const config = {
  apiKey: process.env.NEXT_PUBLIC_FIREBASE_API_KEY,
  authDomain: process.env.NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN,
  projectId: process.env.NEXT_PUBLIC_FIREBASE_PROJECT_ID,
  storageBucket: process.env.NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET
};

export function getFirebaseClientApp() {
  if (!config.apiKey || !config.authDomain || !config.projectId) {
    return null;
  }
  return getApps().length > 0 ? getApp() : initializeApp(config);
}
