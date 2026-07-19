# Eventapp — desarrollo local

App Next.js con Firestore (Firebase). En local necesitas **Node 20+**, **npm**, y un **proyecto Firebase** con Firestore activo.

## Instalación

```bash
git clone <url-del-repositorio>
cd eventapp
npm install
cp .env.example .env.local
```

## Firebase: qué preparar

Todo debe apuntar al **mismo** proyecto Firebase.

1. **Proyecto y Firestore**  
   En [Firebase Console](https://console.firebase.google.com) crea un proyecto (o usa uno existente). Ve a **Compilación → Firestore Database** y crea la base (modo inicial el que prefieras; el servidor usa Admin SDK y no depende de las reglas para leer/escribir desde el backend).

2. **Cuenta de servicio (JSON)**  
   Sirve para el servidor: API routes, lecturas a Firestore y `npm run seed`.  
   **Configuración del proyecto** (engranaje) → **Cuentas de servicio** → **Generar nueva clave privada**. Descarga el `.json` y **no lo subas a git** (el repo ignora `*-firebase-adminsdk-*.json`). Pon el archivo en la **raíz del proyecto** junto a `package.json`.

3. **App web (config del cliente)**  
   En **Configuración del proyecto → Tus aplicaciones** añade una app **web** (`</>`). En el snippet `firebaseConfig` aparecen `apiKey`, `authDomain` y `projectId` — los usarás en `.env.local`.

## Variables de entorno

Edita `.env.local` (parte de `.env.example`):

| Variable | Origen |
|----------|--------|
| `FIREBASE_SERVICE_ACCOUNT_PATH` | Ruta al JSON, p. ej. `./mi-proyecto-firebase-adminsdk-xxxxx.json` |
| `NEXT_PUBLIC_FIREBASE_API_KEY` | `firebaseConfig.apiKey` |
| `NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN` | `firebaseConfig.authDomain` |
| `NEXT_PUBLIC_FIREBASE_PROJECT_ID` | Debe coincidir con el `project_id` del JSON |
| `NEXT_PUBLIC_APP_URL` | `http://localhost:3000` (o el puerto si cambias) |

**Alternativa sin archivo JSON:** en `.env.local` puedes usar `NEXT_PUBLIC_FIREBASE_PROJECT_ID`, `FIREBASE_CLIENT_EMAIL` y `FIREBASE_PRIVATE_KEY` (mismos campos que en el JSON; la clave en una línea con `\n` en el PEM). En local suele ser más simple el JSON.

## Seed y arranque

Con Firestore creado y credenciales bien puestas:

```bash
npm run seed
npm run dev
```

Abre [http://localhost:3000](http://localhost:3000). Tras el seed, una ruta de prueba típica es `/matias-cata/inv_mn_001` (invitación: añade `/invite` al final si usas esa ruta).

## Sin Firebase (solo mock)

Si no configuras credenciales de Admin, el código puede usar **datos en memoria** del repo para ver la UI; no es tu Firestore real.

## Si algo falla

- **No encuentra el JSON:** revisa que `FIREBASE_SERVICE_ACCOUNT_PATH` sea relativo a la carpeta del proyecto y que el archivo exista.
- **Seed dice que no hay credenciales:** falta el JSON o el trío `NEXT_PUBLIC_FIREBASE_PROJECT_ID` + `FIREBASE_CLIENT_EMAIL` + `FIREBASE_PRIVATE_KEY`.
- **Puerto ocupado:** `npx next dev -p 3001` y ajusta `NEXT_PUBLIC_APP_URL`.

En producción (Vercel, etc.) no uses rutas a archivos locales: define las mismas variables en el panel del hosting.
