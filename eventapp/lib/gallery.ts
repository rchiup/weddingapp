import {
  getFirestore,
  collection,
  addDoc,
  serverTimestamp,
  getDocs,
  query,
  where,
  orderBy,
  doc,
  getDoc,
  setDoc,
  deleteDoc,
  getCountFromServer
} from "firebase/firestore";
import { getFirebaseClientApp } from "@/lib/firebase/client";

export type GalleryPhoto = {
  id: string;
  url: string;
  fileName: string;
  createdAt: string;
  weddingSlug: string;
  inviteToken: string;
};

export type GalleryPhotoMeta = {
  likeCount: number;
  commentCount: number;
  userLiked: boolean;
};

export type GalleryComment = {
  id: string;
  text: string;
  inviteToken: string;
  createdAt: string;
};

type UploadParams = {
  weddingSlug: string;
  inviteToken: string;
  file: File;
};

type GetPhotosParams = {
  weddingSlug: string;
  inviteToken: string;
};

function requireClientApp() {
  const app = getFirebaseClientApp();
  if (!app) {
    console.log("Gallery: Firebase client no configurado.");
    throw new Error("Firebase client no configurado. Revisa NEXT_PUBLIC_FIREBASE_* en .env.local");
  }
  return app;
}

function toIsoString(value: unknown) {
  if (!value) return new Date().toISOString();
  if (typeof value === "string") return value;
  if (typeof value === "object" && "toDate" in (value as { toDate?: () => Date })) {
    return (value as { toDate: () => Date }).toDate().toISOString();
  }
  return new Date().toISOString();
}

function resolveFileExtension(file: File) {
  const parts = file.name.split(".");
  const ext = parts.length > 1 ? parts.at(-1) : "";
  return ext ? `.${ext}` : ".jpg";
}

export async function uploadPhoto(params: UploadParams): Promise<GalleryPhoto> {
  const { weddingSlug, inviteToken, file } = params;
  console.log("Gallery uploadPhoto start", { weddingSlug, inviteToken, name: file.name, size: file.size });
  const app = requireClientApp();
  const firestore = getFirestore(app);

  const cloudName = process.env.NEXT_PUBLIC_CLOUDINARY_CLOUD_NAME;
  const uploadPreset = process.env.NEXT_PUBLIC_CLOUDINARY_UPLOAD_PRESET;
  if (!cloudName || !uploadPreset) {
    console.log("Gallery uploadPhoto missing Cloudinary env", { cloudName, uploadPreset });
    throw new Error(
      "Cloudinary no configurado. Define NEXT_PUBLIC_CLOUDINARY_CLOUD_NAME y NEXT_PUBLIC_CLOUDINARY_UPLOAD_PRESET."
    );
  }

  const timestamp = Date.now();
  const fileId = `${timestamp}-${Math.random().toString(36).slice(2, 8)}`;
  const extension = resolveFileExtension(file);
  const folder = `gallery/${weddingSlug}/${inviteToken}`;
  const publicId = `${fileId}${extension}`;
  const formData = new FormData();
  formData.append("file", file);
  formData.append("upload_preset", uploadPreset);
  formData.append("folder", folder);
  formData.append("public_id", publicId);

  const uploadUrl = `https://api.cloudinary.com/v1_1/${cloudName}/image/upload`;
  const response = await fetch(uploadUrl, {
    method: "POST",
    body: formData
  });
  if (!response.ok) {
    const detail = await response.text();
    console.log("Gallery uploadPhoto Cloudinary error", detail);
    throw new Error(`Cloudinary upload failed: ${detail}`);
  }
  const payload = (await response.json()) as { secure_url?: string; url?: string };
  const imageUrl = payload.secure_url ?? payload.url ?? "";
  if (!imageUrl) {
    console.log("Gallery uploadPhoto Cloudinary missing imageUrl", payload);
    throw new Error("Cloudinary upload failed: missing imageUrl.");
  }

  const createdAt = new Date().toISOString();
  console.log("Gallery uploadPhoto Firestore write", { imageUrl, createdAt });
  const docRef = await addDoc(collection(firestore, "gallery"), {
    imageUrl,
    weddingSlug,
    inviteToken,
    createdAt: serverTimestamp()
  });

  return {
    id: docRef.id,
    url: imageUrl,
    fileName: file.name,
    createdAt,
    weddingSlug,
    inviteToken
  };
}

export async function getPhotos(params: GetPhotosParams): Promise<GalleryPhoto[]> {
  const { weddingSlug } = params;
  console.log("Gallery getPhotos start", { weddingSlug });
  const app = requireClientApp();
  const firestore = getFirestore(app);

  const galleryRef = collection(firestore, "gallery");
  const snapshot = await getDocs(
    query(galleryRef, where("weddingSlug", "==", weddingSlug), orderBy("createdAt", "desc"))
  );
  console.log("Gallery getPhotos docs:", snapshot.docs.length);

  return snapshot.docs.map((doc) => {
    const data = doc.data() as {
      imageUrl?: string;
      weddingSlug?: string;
      inviteToken?: string;
      createdAt?: unknown;
    };

    return {
      id: doc.id,
      url: data.imageUrl ?? "",
      fileName: doc.id,
      createdAt: toIsoString(data.createdAt ?? new Date()),
      weddingSlug: data.weddingSlug ?? weddingSlug,
      inviteToken: data.inviteToken ?? ""
    };
  });
}

export async function getPhotoMeta(params: {
  photoId: string;
  inviteToken: string;
}): Promise<GalleryPhotoMeta> {
  const { photoId, inviteToken } = params;
  console.log("Gallery getPhotoMeta start", { photoId, inviteToken });
  const app = requireClientApp();
  const firestore = getFirestore(app);

  const likesRef = collection(firestore, "gallery", photoId, "likes");
  const commentsRef = collection(firestore, "gallery", photoId, "comments");
  const userLikeRef = doc(firestore, "gallery", photoId, "likes", inviteToken);

  const [likesSnap, commentsSnap, userLikeSnap] = await Promise.all([
    getDocs(likesRef),
    getDocs(commentsRef),
    getDoc(userLikeRef)
  ]);

  return {
    likeCount: likesSnap.size,
    commentCount: commentsSnap.size,
    userLiked: userLikeSnap.exists()
  };
}

export async function toggleLike(params: {
  photoId: string;
  inviteToken: string;
}): Promise<{ liked: boolean; likeCount: number }> {
  const { photoId, inviteToken } = params;
  const app = requireClientApp();
  const firestore = getFirestore(app);
  const userLikeRef = doc(firestore, "gallery", photoId, "likes", inviteToken);
  const snap = await getDoc(userLikeRef);

  if (snap.exists()) {
    await deleteDoc(userLikeRef);
  } else {
    await setDoc(userLikeRef, { createdAt: serverTimestamp(), inviteToken });
  }

  const likesRef = collection(firestore, "gallery", photoId, "likes");
  const likesSnap = await getDocs(likesRef);
  return { liked: !snap.exists(), likeCount: likesSnap.size };
}

export async function addComment(params: {
  photoId: string;
  inviteToken: string;
  text: string;
}): Promise<number> {
  const { photoId, inviteToken, text } = params;
  const app = requireClientApp();
  const firestore = getFirestore(app);
  const commentsRef = collection(firestore, "gallery", photoId, "comments");

  await addDoc(commentsRef, {
    text,
    inviteToken,
    createdAt: serverTimestamp()
  });

  const commentsSnap = await getDocs(commentsRef);
  return commentsSnap.size;
}

export async function getComments(photoId: string): Promise<GalleryComment[]> {
  const app = requireClientApp();
  const firestore = getFirestore(app);
  const commentsRef = collection(firestore, "gallery", photoId, "comments");
  const snapshot = await getDocs(query(commentsRef, orderBy("createdAt", "asc")));
  return snapshot.docs.map((commentDoc) => {
    const data = commentDoc.data() as {
      text?: string;
      inviteToken?: string;
      createdAt?: unknown;
    };
    return {
      id: commentDoc.id,
      text: data.text ?? "",
      inviteToken: data.inviteToken ?? "",
      createdAt: toIsoString(data.createdAt)
    };
  });
}
