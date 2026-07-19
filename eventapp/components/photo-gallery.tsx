"use client";

import { ChangeEvent, DragEvent, useCallback, useEffect, useMemo, useRef, useState } from "react";
import { useApp } from "@/lib/app-context";
import { backend, backendUpload, type RecordData } from "@/lib/data";

type Photo = RecordData & {
  photoId: string;
  imageUrl: string;
  mediaUrl: string;
  mediaType: string;
  userId: string;
  userName: string;
  visibility: string;
  createdAt?: string;
};

type Comment = { id: string; userId: string; name: string; message: string; timestamp?: string };

const MAX_SELECTION = 8;
const MAX_SOURCE_BYTES = 25 * 1024 * 1024;
const MAX_UPLOAD_BYTES = 4.6 * 1024 * 1024;

function normalizePhoto(value: Record<string, unknown>): Photo {
  const photoId = String(value.photoId || value.id || "");
  const imageUrl = String(value.mediaUrl || value.imageUrl || value.url || "");
  return {
    ...(value as RecordData),
    id: photoId,
    photoId,
    imageUrl,
    mediaUrl: imageUrl,
    mediaType: String(value.mediaType || "image"),
    userId: String(value.userId || value.uploadedBy || ""),
    userName: String(value.userName || value.uploadedByName || "Invitado"),
    visibility: String(value.visibility || "public"),
    createdAt: value.createdAt ? String(value.createdAt) : undefined,
  };
}

function readableError(reason: unknown) {
  const message = reason instanceof Error ? reason.message : String(reason);
  if (/Failed to fetch|NetworkError|Load failed/i.test(message)) return "No pudimos conectar con el servicio de fotos. Revisa tu conexión e intenta otra vez.";
  if (/413|too large|tamaño|máximo/i.test(message)) return "La foto sigue siendo demasiado pesada. Prueba con otra imagen.";
  return message;
}

export function PhotoGallery() {
  const { session } = useApp();
  const [photos, setPhotos] = useState<Photo[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [uploadOpen, setUploadOpen] = useState(false);
  const [selectedIndex, setSelectedIndex] = useState<number | null>(null);

  const load = useCallback(async () => {
    setLoading(true); setError("");
    try {
      const params = new URLSearchParams({ viewerId: session.userId });
      if (session.isAdmin) params.set("includePrivate", "true");
      const data = await backend(`/api/gallery/event/${encodeURIComponent(session.eventId)}?${params}`);
      setPhotos((data.items || []).map(normalizePhoto).filter((photo: Photo) => photo.mediaUrl));
    } catch (reason) { setError(readableError(reason)); }
    finally { setLoading(false); }
  }, [session.eventId, session.userId, session.isAdmin]);

  useEffect(() => { void load(); }, [load]);

  return <>
    <div className="photo-head">
      <div><h2>Fotos del evento</h2><p>Los recuerdos de todos, en un solo lugar.</p></div>
      <button className="primary" onClick={() => setUploadOpen(true)}>＋ Subir fotos</button>
    </div>
    {error && <div className="notice error photo-error"><span>{error}</span><button onClick={load}>Reintentar</button></div>}
    {loading && <GallerySkeleton />}
    {!loading && !error && photos.length === 0 && <div className="photo-empty"><span>📷</span><h3>Aún no hay fotos</h3><p>Sé la primera persona en compartir un recuerdo.</p><button className="primary" onClick={() => setUploadOpen(true)}>Elegir fotos</button></div>}
    {!loading && photos.length > 0 && <div className="photo-grid">{photos.map((photo, index) => <PhotoTile key={photo.photoId} photo={photo} onOpen={() => setSelectedIndex(index)} />)}</div>}
    {uploadOpen && <UploadDialog onClose={() => setUploadOpen(false)} onUploaded={async () => { setUploadOpen(false); await load(); }} />}
    {selectedIndex !== null && photos[selectedIndex] && <PhotoDialog
      photo={photos[selectedIndex]}
      position={selectedIndex + 1}
      total={photos.length}
      onPrevious={selectedIndex > 0 ? () => setSelectedIndex(selectedIndex - 1) : undefined}
      onNext={selectedIndex < photos.length - 1 ? () => setSelectedIndex(selectedIndex + 1) : undefined}
      onClose={() => setSelectedIndex(null)}
      onDeleted={async () => { setSelectedIndex(null); await load(); }}
    />}
  </>;
}

function GallerySkeleton() {
  return <div className="photo-grid photo-skeleton" aria-label="Cargando fotos">{[1, 2, 3, 4].map((item) => <div key={item}><span /><small /></div>)}</div>;
}

function PhotoTile({ photo, onOpen }: { photo: Photo; onOpen: () => void }) {
  const { session } = useApp();
  const [likes, setLikes] = useState(0);
  const [liked, setLiked] = useState(false);
  const [comments, setComments] = useState(0);
  const [busy, setBusy] = useState(false);
  const [imageFailed, setImageFailed] = useState(false);
  const [showLikeBurst, setShowLikeBurst] = useState(false);
  const lastTapAt = useRef(0);
  const openTimer = useRef<ReturnType<typeof setTimeout> | null>(null);
  const burstTimer = useRef<ReturnType<typeof setTimeout> | null>(null);
  const hasInteracted = useRef(false);
  const initialLikeRequest = useRef<AbortController | null>(null);

  useEffect(() => {
    const controller = new AbortController();
    initialLikeRequest.current = controller;
    backend(`/api/gallery/photos/${photo.photoId}/likes?userId=${encodeURIComponent(session.userId)}`, { signal: controller.signal }).then((likeData) => {
      if (!hasInteracted.current) {
        setLikes(Number(likeData.count || 0));
        setLiked(Boolean(likeData.userLiked));
      }
    }).catch(() => { /* la foto sigue disponible aunque falle el contador */ });
    backend(`/api/gallery/photos/${photo.photoId}/comments/count`).then((commentData) => {
      setComments(Number(commentData.count || 0));
    }).catch(() => { /* los comentarios se cargan nuevamente al abrir la foto */ });
    return () => controller.abort();
  }, [photo.photoId, session.userId]);

  useEffect(() => () => {
    if (openTimer.current) clearTimeout(openTimer.current);
    if (burstTimer.current) clearTimeout(burstTimer.current);
  }, []);

  const burst = () => {
    setShowLikeBurst(false);
    requestAnimationFrame(() => setShowLikeBurst(true));
    if (burstTimer.current) clearTimeout(burstTimer.current);
    burstTimer.current = setTimeout(() => setShowLikeBurst(false), 700);
    if ("vibrate" in navigator) navigator.vibrate(35);
  };

  const toggle = async (forceLike = false) => {
    if (busy) return;
    if (forceLike && liked) { burst(); return; }
    hasInteracted.current = true;
    initialLikeRequest.current?.abort();
    const previousLiked = liked; const previousLikes = likes;
    const nextLiked = forceLike ? true : !previousLiked;
    setLiked(nextLiked); setLikes(Math.max(0, previousLikes + (nextLiked ? 1 : -1))); setBusy(true);
    if (forceLike) burst();
    try {
      const result = await backend(`/api/gallery/photos/${photo.photoId}/likes/toggle`, {
        method: "POST",
        body: JSON.stringify({ userId: session.userId, name: session.userName || "Invitado" }),
      });
      setLikes(Number(result.count || 0)); setLiked(Boolean(result.liked));
    } catch { setLiked(previousLiked); setLikes(previousLikes); }
    finally { setBusy(false); }
  };

  const handleMediaClick = () => {
    const now = performance.now();
    if (now - lastTapAt.current <= 320) {
      if (openTimer.current) clearTimeout(openTimer.current);
      openTimer.current = null; lastTapAt.current = 0;
      void toggle(true);
      return;
    }
    lastTapAt.current = now;
    openTimer.current = setTimeout(() => { lastTapAt.current = 0; onOpen(); }, 280);
  };

  const video = photo.mediaType === "video" || /\.(mp4|mov|webm)(\?|$)/i.test(photo.mediaUrl);
  return <article className="photo-card">
    <button className="photo-media" onClick={(event) => event.detail === 0 ? onOpen() : handleMediaClick()} aria-label={video ? "Abrir video" : "Abrir foto"}>
      {imageFailed ? <span className="photo-broken">No pudimos cargar esta foto<br/><small>Toca para reintentar</small></span> : video ? <video src={photo.mediaUrl} muted playsInline preload="metadata" onError={() => setImageFailed(true)} /> : <img src={photo.mediaUrl} alt={`Foto subida por ${photo.userName}`} loading="lazy" onError={() => setImageFailed(true)} />}
      {video && !imageFailed && <span className="play-badge">▶</span>}
      {photo.visibility === "novios" && <span className="private-badge">Sólo novios</span>}
      {showLikeBurst && <span className="like-burst" aria-hidden="true">♥</span>}
    </button>
    <div className="photo-meta"><span>Por <b>{photo.userName}</b></span><div className="photo-actions"><button className={liked ? "liked" : ""} onClick={() => void toggle()} disabled={busy} aria-label={liked ? "Quitar me gusta" : "Me gusta"}>♥ {likes}</button><button onClick={onOpen} aria-label="Ver comentarios">◯ {comments}</button></div></div>
  </article>;
}

async function decodeImage(file: File) {
  if ("createImageBitmap" in window) return createImageBitmap(file, { imageOrientation: "from-image" });
  const url = URL.createObjectURL(file);
  try {
    const image = new Image();
    image.src = url;
    await image.decode();
    return image;
  } finally { URL.revokeObjectURL(url); }
}

async function preparePhoto(file: File) {
  if (!file.type.startsWith("image/")) throw new Error(`${file.name}: selecciona una imagen.`);
  if (file.size > MAX_SOURCE_BYTES) throw new Error(`${file.name}: el archivo original supera 25 MB.`);
  if ((file.type === "image/jpeg" || file.type === "image/png") && file.size <= MAX_UPLOAD_BYTES) return file;

  let source: ImageBitmap | HTMLImageElement;
  try { source = await decodeImage(file); }
  catch { throw new Error(`${file.name}: este formato no se puede convertir. Usa JPG, PNG o una foto tomada desde el teléfono.`); }
  const sourceWidth = source.width; const sourceHeight = source.height;
  const scale = Math.min(1, 2200 / Math.max(sourceWidth, sourceHeight));
  const canvas = document.createElement("canvas");
  canvas.width = Math.max(1, Math.round(sourceWidth * scale)); canvas.height = Math.max(1, Math.round(sourceHeight * scale));
  const context = canvas.getContext("2d");
  if (!context) throw new Error("No pudimos preparar la foto en este navegador.");
  context.drawImage(source, 0, 0, canvas.width, canvas.height);
  if ("close" in source && typeof source.close === "function") source.close();

  let quality = .88; let blob: Blob | null = null;
  while (quality >= .52) {
    blob = await new Promise<Blob | null>((resolve) => canvas.toBlob(resolve, "image/jpeg", quality));
    if (blob && blob.size <= MAX_UPLOAD_BYTES) break;
    quality -= .08;
  }
  if (!blob || blob.size > MAX_UPLOAD_BYTES) throw new Error(`${file.name}: no pudimos dejar la foto bajo 5 MB.`);
  const baseName = file.name.replace(/\.[^.]+$/, "") || "foto";
  return new File([blob], `${baseName}.jpg`, { type: "image/jpeg", lastModified: Date.now() });
}

function UploadDialog({ onClose, onUploaded }: { onClose: () => void; onUploaded: () => void }) {
  const { session } = useApp(); const input = useRef<HTMLInputElement>(null);
  const [files, setFiles] = useState<File[]>([]); const [visibility, setVisibility] = useState("public");
  const [progress, setProgress] = useState(0); const [error, setError] = useState("");
  const [busy, setBusy] = useState(false); const [dragging, setDragging] = useState(false); const [stage, setStage] = useState("");
  const previews = useMemo(() => files.map((file) => ({ file, url: URL.createObjectURL(file), key: `${file.name}-${file.lastModified}-${file.size}` })), [files]);

  useEffect(() => () => previews.forEach((item) => URL.revokeObjectURL(item.url)), [previews]);
  useEffect(() => {
    const keyDown = (event: KeyboardEvent) => { if (event.key === "Escape" && !busy) onClose(); };
    const paste = (event: ClipboardEvent) => {
      const pasted = Array.from(event.clipboardData?.files || []).filter((file) => file.type.startsWith("image/"));
      if (pasted.length) { event.preventDefault(); addFiles(pasted); }
    };
    document.addEventListener("keydown", keyDown); document.addEventListener("paste", paste);
    return () => { document.removeEventListener("keydown", keyDown); document.removeEventListener("paste", paste); };
  });

  const addFiles = (incoming: File[]) => {
    const images = incoming.filter((file) => file.type.startsWith("image/"));
    if (images.length !== incoming.length) setError("Por ahora esta galería acepta fotos; los videos todavía no están habilitados en el servidor.");
    else setError("");
    setFiles((current) => {
      const seen = new Set(current.map((file) => `${file.name}-${file.size}-${file.lastModified}`));
      const unique = images.filter((file) => !seen.has(`${file.name}-${file.size}-${file.lastModified}`));
      const next = [...current, ...unique].slice(0, MAX_SELECTION);
      if (current.length + unique.length > MAX_SELECTION) setError(`Puedes subir hasta ${MAX_SELECTION} fotos a la vez.`);
      return next;
    });
  };
  const choose = (event: ChangeEvent<HTMLInputElement>) => { addFiles(Array.from(event.target.files || [])); event.target.value = ""; };
  const drop = (event: DragEvent) => { event.preventDefault(); setDragging(false); addFiles(Array.from(event.dataTransfer.files || [])); };
  const removeFile = (key: string) => setFiles((current) => current.filter((file) => `${file.name}-${file.lastModified}-${file.size}` !== key));

  const upload = async () => {
    if (!files.length || busy) return;
    setBusy(true); setError(""); setProgress(0);
    try {
      for (let index = 0; index < files.length; index++) {
        setStage(`Preparando ${index + 1} de ${files.length}…`);
        const file = await preparePhoto(files[index]);
        const form = new FormData();
        form.set("file", file); form.set("eventId", session.eventId); form.set("userId", session.userId);
        form.set("userName", session.userName || "Invitado"); form.set("visibility", visibility);
        setStage(`Subiendo ${index + 1} de ${files.length}…`);
        await backendUpload("/api/gallery/upload", form, (fileProgress) => setProgress(Math.round(((index + fileProgress / 100) / files.length) * 100)));
      }
      setProgress(100); await onUploaded();
    } catch (reason) { setError(readableError(reason)); }
    finally { setBusy(false); setStage(""); }
  };

  return <div className="modal-backdrop" role="presentation" onMouseDown={(event) => event.target === event.currentTarget && !busy && onClose()}><section className="modal-card" role="dialog" aria-modal="true" aria-label="Subir fotos"><header><div><span className="eyebrow">GALERÍA</span><h2>Comparte tus recuerdos</h2></div><button className="icon-button" onClick={onClose} disabled={busy} aria-label="Cerrar">×</button></header>
    <input ref={input} type="file" accept="image/*" multiple hidden onChange={choose}/>
    <button className={`upload-drop ${dragging ? "dragging" : ""}`} onClick={() => input.current?.click()} onDragEnter={(event) => { event.preventDefault(); setDragging(true); }} onDragOver={(event) => event.preventDefault()} onDragLeave={() => setDragging(false)} onDrop={drop}><b>{dragging ? "Suelta las fotos aquí" : "＋ Elegir fotos"}</b><span>JPG, PNG o foto del teléfono · hasta {MAX_SELECTION} por vez</span><small>También puedes pegarlas o arrastrarlas</small></button>
    {previews.length > 0 && <div className="preview-strip">{previews.map(({ file, url, key }) => <div className="preview-item" key={key}><img src={url} alt={`Vista previa de ${file.name}`}/><button onClick={() => removeFile(key)} disabled={busy} aria-label={`Quitar ${file.name}`}>×</button></div>)}</div>}
    <label className="privacy-choice">¿Quién puede verlas?<select value={visibility} onChange={(event) => setVisibility(event.target.value)} disabled={busy}><option value="public">Todos los invitados</option><option value="novios">Sólo los novios</option></select></label>
    {busy && <><div className="upload-stage">{stage}</div><div className="progress" aria-label={`Subida ${progress}%`}><span style={{ width: `${progress}%` }}/><b>{progress}%</b></div></>}
    {error && <div className="notice error">{error}</div>}
    <div className="modal-actions"><button className="ghost-button" onClick={onClose} disabled={busy}>Cancelar</button><button className="primary" onClick={upload} disabled={!files.length || busy}>{busy ? "Subiendo…" : `Subir ${files.length || ""} ${files.length === 1 ? "foto" : "fotos"}`}</button></div>
  </section></div>;
}

function PhotoDialog({ photo, position, total, onPrevious, onNext, onClose, onDeleted }: { photo: Photo; position: number; total: number; onPrevious?: () => void; onNext?: () => void; onClose: () => void; onDeleted: () => void }) {
  const { session } = useApp(); const [comments, setComments] = useState<Comment[]>([]); const [message, setMessage] = useState(""); const [error, setError] = useState(""); const [sending, setSending] = useState(false); const canDelete = session.isAdmin || session.userId === photo.userId;
  const load = useCallback(() => backend(`/api/gallery/photos/${photo.photoId}/comments`).then((data) => setComments(Array.isArray(data) ? data : [])).catch((reason) => setError(readableError(reason))), [photo.photoId]);
  useEffect(() => { setComments([]); setError(""); void load(); }, [load]);
  useEffect(() => {
    const previousOverflow = document.body.style.overflow; document.body.style.overflow = "hidden";
    const keyDown = (event: KeyboardEvent) => { if (event.key === "Escape") onClose(); if (event.key === "ArrowLeft") onPrevious?.(); if (event.key === "ArrowRight") onNext?.(); };
    document.addEventListener("keydown", keyDown);
    return () => { document.body.style.overflow = previousOverflow; document.removeEventListener("keydown", keyDown); };
  }, [onClose, onPrevious, onNext]);
  const send = async () => { if (!message.trim() || sending) return; setSending(true); setError(""); try { await backend(`/api/gallery/photos/${photo.photoId}/comments`, { method: "POST", body: JSON.stringify({ userId: session.userId, name: session.userName || "Invitado", message: message.trim() }) }); setMessage(""); await load(); } catch (reason) { setError(readableError(reason)); } finally { setSending(false); } };
  const remove = async () => { if (!canDelete || !confirm("¿Eliminar esta foto? Esta acción no se puede deshacer.")) return; try { await backend(`/api/gallery/photos/${photo.photoId}`, { method: "DELETE" }); await onDeleted(); } catch (reason) { setError(readableError(reason)); } };
  const video = photo.mediaType === "video" || /\.(mp4|mov|webm)(\?|$)/i.test(photo.mediaUrl);
  const formattedDate = photo.createdAt && !Number.isNaN(Date.parse(photo.createdAt)) ? new Date(photo.createdAt).toLocaleString("es-CL") : "";
  return <div className="modal-backdrop dark" role="presentation" onMouseDown={(event) => event.target === event.currentTarget && onClose()}><section className="photo-dialog" role="dialog" aria-modal="true" aria-label={`Foto ${position} de ${total}`}><button className="photo-close" onClick={onClose} aria-label="Cerrar">×</button><div className="photo-stage">{video ? <video src={photo.mediaUrl} controls autoPlay playsInline/> : <img src={photo.mediaUrl} alt={`Foto de ${photo.userName}`}/>}<span className="photo-counter">{position} / {total}</span>{onPrevious && <button className="photo-nav previous" onClick={onPrevious} aria-label="Foto anterior">‹</button>}{onNext && <button className="photo-nav next" onClick={onNext} aria-label="Foto siguiente">›</button>}</div><aside className="comments-panel"><div className="comments-title"><div><b>{photo.userName}</b><small>{formattedDate}</small></div><div className="dialog-tools"><a href={photo.mediaUrl} target="_blank" rel="noreferrer" aria-label="Abrir original">↗</a>{canDelete && <button className="danger-link" onClick={remove}>Eliminar</button>}</div></div><div className="comments-list">{comments.map((comment) => <div className="comment" key={comment.id}><b>{comment.name}</b><p>{comment.message}</p></div>)}{comments.length === 0 && <span className="empty-comments">Todavía no hay comentarios.</span>}</div>{error && <div className="notice error">{error}</div>}<div className="comment-compose"><input value={message} onChange={(event) => setMessage(event.target.value)} onKeyDown={(event) => event.key === "Enter" && void send()} placeholder="Escribe un comentario…" aria-label="Comentario"/><button onClick={send} disabled={!message.trim() || sending}>Enviar</button></div></aside></section></div>;
}
