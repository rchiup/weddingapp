"use client";

import { use, useEffect, useMemo, useRef, useState } from "react";
import Link from "next/link";
import type { GalleryComment, GalleryPhoto, GalleryPhotoMeta } from "@/lib/gallery";
import {
  addComment,
  getComments,
  getPhotoMeta,
  getPhotos,
  toggleLike,
  uploadPhoto
} from "@/lib/gallery";

type GalleryPageProps = {
  params: Promise<{
    weddingSlug: string;
    inviteToken: string;
  }>;
};

const emptyStateCopy = "Aún no hay recuerdos. Sube la primera foto.";

export default function GalleryPage({ params }: GalleryPageProps) {
  const { weddingSlug, inviteToken } = use(params);
  const [photos, setPhotos] = useState<GalleryPhoto[]>([]);
  const [selectedFiles, setSelectedFiles] = useState<File[]>([]);
  const [previewUrl, setPreviewUrl] = useState<string | null>(null);
  const [isUploading, setIsUploading] = useState(false);
  const fileInputRef = useRef<HTMLInputElement | null>(null);
  const [photoMeta, setPhotoMeta] = useState<Record<string, GalleryPhotoMeta>>({});
  const [activePhoto, setActivePhoto] = useState<GalleryPhoto | null>(null);
  const [activeMeta, setActiveMeta] = useState<GalleryPhotoMeta | null>(null);
  const [activeComments, setActiveComments] = useState<GalleryComment[]>([]);
  const [commentInput, setCommentInput] = useState("");
  const [loadingActive, setLoadingActive] = useState(false);
  const [showHeart, setShowHeart] = useState(false);
  const lastTapRef = useRef<number>(0);

  useEffect(() => {
    let isMounted = true;
    getPhotos({ weddingSlug, inviteToken })
      .then((items) => {
        if (isMounted) {
          setPhotos(items);
        }
      })
      .catch((error) => {
        console.log("Error cargando galería:", error);
      });
    return () => {
      isMounted = false;
    };
  }, [weddingSlug, inviteToken]);

  useEffect(() => {
    let isMounted = true;
    if (photos.length === 0) {
      setPhotoMeta({});
      return () => {
        isMounted = false;
      };
    }
    Promise.all(
      photos.map(
        async (photo) =>
          [photo.id, await getPhotoMeta({ photoId: photo.id, inviteToken })] as const
      )
    )
      .then((entries) => {
        if (isMounted) {
          setPhotoMeta(Object.fromEntries(entries));
        }
      })
      .catch((error) => {
        console.log("Error cargando reacciones:", error);
      });
    return () => {
      isMounted = false;
    };
  }, [photos, inviteToken]);

  useEffect(() => {
    return () => {
      if (previewUrl) {
        URL.revokeObjectURL(previewUrl);
      }
    };
  }, [previewUrl]);

  const handleFileChange = (event: React.ChangeEvent<HTMLInputElement>) => {
    const files = Array.from(event.target.files ?? []);
    if (files.length === 0) {
      setSelectedFiles([]);
      setPreviewUrl(null);
      return;
    }

    if (previewUrl) {
      URL.revokeObjectURL(previewUrl);
    }

    setSelectedFiles(files);
    setPreviewUrl(URL.createObjectURL(files[0]));
  };

  const handleUpload = async () => {
    if (selectedFiles.length === 0) return;
    setIsUploading(true);
    try {
      console.log("Gallery UI upload start", selectedFiles.length);
      for (const file of selectedFiles) {
        await uploadPhoto({ weddingSlug, inviteToken, file });
      }
      const refreshed = await getPhotos({ weddingSlug, inviteToken });
      setPhotos(refreshed);
      setSelectedFiles([]);
      if (fileInputRef.current) {
        fileInputRef.current.value = "";
      }
      if (previewUrl) {
        URL.revokeObjectURL(previewUrl);
      }
      setPreviewUrl(null);
    } catch (error) {
      console.log("Error subiendo foto:", error);
    } finally {
      setIsUploading(false);
    }
  };

  const handlePrimaryAction = () => {
    if (isUploading) return;
    if (selectedFiles.length === 0) {
      fileInputRef.current?.click();
      return;
    }
    void handleUpload();
  };

  const handleToggleLike = async (photoId: string) => {
    try {
      const result = await toggleLike({ photoId, inviteToken });
      setPhotoMeta((current) => ({
        ...current,
        [photoId]: {
          likeCount: result.likeCount,
          commentCount: current[photoId]?.commentCount ?? 0,
          userLiked: result.liked
        }
      }));
      if (activePhoto?.id === photoId) {
        setActiveMeta((current) => ({
          likeCount: result.likeCount,
          commentCount: current?.commentCount ?? 0,
          userLiked: result.liked
        }));
      }
    } catch (error) {
      console.log("Error dando like:", error);
    }
  };

  const triggerHeart = () => {
    setShowHeart(true);
    window.setTimeout(() => setShowHeart(false), 550);
  };

  const handleAddComment = async (photoId: string) => {
    const text = commentInput.trim();
    if (!text) return;
    try {
      const count = await addComment({ photoId, inviteToken, text: text.trim() });
      setPhotoMeta((current) => ({
        ...current,
        [photoId]: {
          likeCount: current[photoId]?.likeCount ?? 0,
          commentCount: count,
          userLiked: current[photoId]?.userLiked ?? false
        }
      }));
      if (activePhoto?.id === photoId) {
        const comments = await getComments(photoId);
        setActiveComments(comments);
        setActiveMeta((current) => ({
          likeCount: current?.likeCount ?? 0,
          commentCount: count,
          userLiked: current?.userLiked ?? false
        }));
        setCommentInput("");
      }
    } catch (error) {
      console.log("Error agregando comentario:", error);
    }
  };
  const gridItems = useMemo(() => photos, [photos]);

  const openPhoto = async (photo: GalleryPhoto) => {
    setActivePhoto(photo);
    setLoadingActive(true);
    try {
      const [meta, comments] = await Promise.all([
        getPhotoMeta({ photoId: photo.id, inviteToken }),
        getComments(photo.id)
      ]);
      setActiveMeta(meta);
      setActiveComments(comments);
    } catch (error) {
      console.log("Error abriendo foto:", error);
    } finally {
      setLoadingActive(false);
    }
  };

  const closePhoto = () => {
    setActivePhoto(null);
    setActiveMeta(null);
    setActiveComments([]);
    setCommentInput("");
    setShowHeart(false);
  };

  return (
    <main className="mx-auto w-full max-w-4xl px-4 pb-10 pt-6">
      <div className="flex items-center justify-between gap-4">
        <div className="flex items-center gap-3">
          <Link
            className="text-sm font-semibold text-neutral-700"
            href={`/${weddingSlug}/${inviteToken}`}
          >
            ←
          </Link>
          <div>
            <p className="display-title text-base font-semibold text-neutral-800">Momentos del día</p>
            <p className="text-xs text-neutral-500">{gridItems.length} recuerdos</p>
          </div>
        </div>
        <div className="flex items-center gap-3">
          <input
            ref={fileInputRef}
            className="hidden"
            type="file"
            accept="image/*"
            multiple
            onChange={handleFileChange}
          />
          <button
            className="cursor-pointer rounded-full bg-neutral-900 px-4 py-2 text-xs font-semibold text-white disabled:cursor-not-allowed disabled:bg-neutral-400"
            onClick={handlePrimaryAction}
            disabled={isUploading}
            type="button"
          >
            {isUploading ? "Subiendo..." : "Subir foto"}
          </button>
        </div>
      </div>

      {previewUrl ? (
        <div className="mt-4 overflow-hidden rounded-2xl border border-neutral-200 bg-white">
          <img className="h-48 w-full object-cover" src={previewUrl} alt="Preview" />
        </div>
      ) : null}

      {gridItems.length === 0 ? (
        <div className="mt-6 rounded-2xl border border-neutral-200 bg-white px-4 py-3 text-sm text-neutral-500">
          {emptyStateCopy}
        </div>
      ) : (
        <div className="mt-6 grid grid-cols-2 gap-4">
          {gridItems.map((photo) => {
            const meta = photoMeta[photo.id] ?? {
              likeCount: 0,
              commentCount: 0,
              userLiked: false
            };
            return (
              <div key={photo.id} className="space-y-2">
                <div className="overflow-hidden rounded-2xl border border-neutral-200 bg-white">
                  <button
                    className="block w-full"
                    onClick={() => openPhoto(photo)}
                    type="button"
                  >
                    <img className="aspect-square w-full object-cover" src={photo.url} alt={photo.fileName} />
                  </button>
                </div>
                <div className="flex items-center justify-between px-1 text-xs text-neutral-500">
                  <button
                    className={`flex items-center gap-1 ${meta.userLiked ? "text-rose-500" : "text-neutral-500"}`}
                    onClick={() => handleToggleLike(photo.id)}
                    type="button"
                  >
                    ♥ {meta.likeCount}
                  </button>
                  <button
                    className="flex items-center gap-1"
                    onClick={() => openPhoto(photo)}
                    type="button"
                  >
                    💬 {meta.commentCount}
                  </button>
                </div>
              </div>
            );
          })}
        </div>
      )}

      {activePhoto ? (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/70 p-4">
          <div className="w-full max-w-5xl overflow-hidden rounded-3xl bg-white shadow-xl">
            <div className="flex items-center justify-between border-b border-neutral-200 px-4 py-3">
              <div className="text-sm font-semibold text-neutral-700">Foto</div>
              <button className="text-sm font-semibold text-neutral-500" onClick={closePhoto} type="button">
                Cerrar
              </button>
            </div>
            <div className="grid gap-4 p-4 md:grid-cols-[1.2fr_0.8fr]">
              <div className="relative overflow-hidden rounded-2xl border border-neutral-200 bg-neutral-100">
                <button
                  className="block w-full"
                  onClick={() => {
                    const now = Date.now();
                    const delta = now - lastTapRef.current;
                    lastTapRef.current = now;
                    if (delta > 0 && delta < 320) {
                      triggerHeart();
                      void handleToggleLike(activePhoto.id);
                    }
                  }}
                  type="button"
                >
                  <img className="w-full object-contain" src={activePhoto.url} alt={activePhoto.fileName} />
                </button>
                {showHeart ? (
                  <div className="pointer-events-none absolute inset-0 flex items-center justify-center">
                    <div className="rounded-full bg-white/70 px-6 py-4 text-3xl text-rose-500">♥</div>
                  </div>
                ) : null}
              </div>
              <div className="flex h-full flex-col gap-3">
                <div className="flex items-center gap-4 text-sm text-neutral-600">
                  <button
                    className={`flex items-center gap-1 ${activeMeta?.userLiked ? "text-rose-500" : "text-neutral-600"}`}
                    onClick={() => handleToggleLike(activePhoto.id)}
                    type="button"
                  >
                    ♥ {activeMeta?.likeCount ?? 0}
                  </button>
                  <span>💬 {activeMeta?.commentCount ?? 0}</span>
                  <span className="text-xs text-neutral-400">Doble click para like</span>
                </div>
                <div className="flex gap-2">
                  <input
                    className="flex-1 rounded-full border border-neutral-200 px-3 py-2 text-sm"
                    placeholder="Escribe un comentario..."
                    value={commentInput}
                    onChange={(event) => setCommentInput(event.target.value)}
                  />
                  <button
                    className="rounded-full bg-neutral-900 px-4 py-2 text-sm font-semibold text-white"
                    onClick={() => handleAddComment(activePhoto.id)}
                    type="button"
                  >
                    Enviar
                  </button>
                </div>
                <div className="flex-1 overflow-auto rounded-2xl border border-neutral-200 p-3 text-sm text-neutral-600">
                  {loadingActive ? (
                    <p>Cargando...</p>
                  ) : activeComments.length === 0 ? (
                    <p>Sin comentarios.</p>
                  ) : (
                    <div className="space-y-3">
                      {activeComments.map((comment) => (
                        <div key={comment.id}>
                          <span className="font-semibold text-neutral-800">
                            {comment.inviteToken || "Invitado"}:
                          </span>{" "}
                          {comment.text}
                        </div>
                      ))}
                    </div>
                  )}
                </div>
              </div>
            </div>
          </div>
        </div>
      ) : null}
    </main>
  );
}
