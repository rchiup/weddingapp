"use client";

import { ChangeEvent, useEffect, useMemo, useRef, useState } from "react";
import { useApp } from "@/lib/app-context";
import { backend, backendForm, type RecordData } from "@/lib/data";

type Photo = RecordData & {
  photoId: string; imageUrl: string; mediaUrl: string; mediaType: string;
  userId: string; userName: string; visibility: string; createdAt?: string;
};
type Comment = { id: string; userId: string; name: string; message: string; timestamp?: string };

function normalizePhoto(value: Record<string, unknown>): Photo {
  const photoId = String(value.photoId || value.id || "");
  const imageUrl = String(value.mediaUrl || value.imageUrl || value.url || "");
  return {
    ...(value as RecordData), id: photoId, photoId, imageUrl,
    mediaUrl: imageUrl, mediaType: String(value.mediaType || "image"),
    userId: String(value.userId || value.uploadedBy || ""),
    userName: String(value.userName || value.uploadedByName || "Invitado"),
    visibility: String(value.visibility || "public"),
    createdAt: value.createdAt ? String(value.createdAt) : undefined,
  };
}

export function PhotoGallery() {
  const { session } = useApp();
  const [photos, setPhotos] = useState<Photo[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [uploadOpen, setUploadOpen] = useState(false);
  const [selected, setSelected] = useState<Photo | null>(null);

  const load = async () => {
    setLoading(true); setError("");
    try {
      const params = new URLSearchParams({ viewerId: session.userId });
      if (session.isAdmin) params.set("includePrivate", "true");
      const data = await backend(`/api/gallery/event/${encodeURIComponent(session.eventId)}?${params}`);
      setPhotos((data.items || []).map(normalizePhoto));
    } catch (e) { setError(e instanceof Error ? e.message : String(e)); }
    finally { setLoading(false); }
  };
  useEffect(() => { void load(); }, [session.eventId, session.userId, session.isAdmin]);

  return <>
    <div className="photo-head">
      <div><h2>Fotos del evento</h2><p>Los recuerdos de todos, en un solo lugar.</p></div>
      <button className="primary" onClick={() => setUploadOpen(true)}>＋ Subir</button>
    </div>
    {error && <div className="notice error">{error}</div>}
    {loading && <div className="loading-line"><span /> Cargando recuerdos…</div>}
    {!loading && photos.length === 0 && <div className="notice">Aún no hay fotos. Sé la primera persona en compartir una.</div>}
    <div className="photo-grid">{photos.map((photo) => <PhotoTile key={photo.photoId} photo={photo} onOpen={() => setSelected(photo)} />)}</div>
    {uploadOpen && <UploadDialog onClose={() => setUploadOpen(false)} onUploaded={async () => { setUploadOpen(false); await load(); }} />}
    {selected && <PhotoDialog photo={selected} onClose={() => setSelected(null)} onDeleted={async () => { setSelected(null); await load(); }} />}
  </>;
}

function PhotoTile({ photo, onOpen }: { photo: Photo; onOpen: () => void }) {
  const { session } = useApp();
  const [likes, setLikes] = useState(0); const [liked, setLiked] = useState(false); const [comments, setComments] = useState(0); const [busy, setBusy] = useState(false);
  useEffect(() => {
    Promise.all([
      backend(`/api/gallery/photos/${photo.photoId}/likes?userId=${encodeURIComponent(session.userId)}`),
      backend(`/api/gallery/photos/${photo.photoId}/comments/count`),
    ]).then(([a,b]) => { setLikes(Number(a.count || 0)); setLiked(Boolean(a.userLiked)); setComments(Number(b.count || 0)); }).catch(() => {});
  }, [photo.photoId, session.userId]);
  const toggle = async () => { if (busy) return; setBusy(true); try { const result = await backend(`/api/gallery/photos/${photo.photoId}/likes/toggle`, { method: "POST", body: JSON.stringify({ userId: session.userId, name: session.userName || "Invitado" }) }); setLikes(Number(result.count || 0)); setLiked(Boolean(result.liked)); } finally { setBusy(false); } };
  const video = photo.mediaType === "video" || /\.(mp4|mov|webm)(\?|$)/i.test(photo.mediaUrl);
  return <article className="photo-card">
    <button className="photo-media" onClick={onOpen} aria-label="Abrir foto">
      {video ? <video src={photo.mediaUrl} muted playsInline preload="metadata" /> : <img src={photo.mediaUrl} alt={`Foto subida por ${photo.userName}`} />}
      {video && <span className="play-badge">▶</span>}
      {photo.visibility === "novios" && <span className="private-badge">Sólo novios</span>}
    </button>
    <div className="photo-meta"><span>Por <b>{photo.userName}</b></span><div className="photo-actions"><button className={liked ? "liked" : ""} onClick={toggle} disabled={busy} aria-label={liked ? "Quitar me gusta" : "Me gusta"}>♥ {likes}</button><button onClick={onOpen} aria-label="Ver comentarios">◯ {comments}</button></div></div>
  </article>;
}

function UploadDialog({ onClose, onUploaded }: { onClose: () => void; onUploaded: () => void }) {
  const { session } = useApp(); const input = useRef<HTMLInputElement>(null);
  const [files, setFiles] = useState<File[]>([]); const [visibility, setVisibility] = useState("public"); const [progress, setProgress] = useState(0); const [error, setError] = useState(""); const [busy, setBusy] = useState(false);
  const previews = useMemo(() => files.map((file) => ({ file, url: URL.createObjectURL(file) })), [files]);
  useEffect(() => () => previews.forEach((x) => URL.revokeObjectURL(x.url)), [previews]);
  const choose = (e: ChangeEvent<HTMLInputElement>) => { const next = Array.from(e.target.files || []); const valid = next.filter((f) => f.type.startsWith("image/") || f.type.startsWith("video/")); setFiles(valid); setError(valid.length !== next.length ? "Algunos archivos no son imágenes o videos compatibles." : ""); };
  const upload = async () => {
    if (!files.length || busy) return; setBusy(true); setError(""); setProgress(0);
    try {
      for (let i=0;i<files.length;i++) {
        const file=files[i]; const max=file.type.startsWith("video/") ? 40 : 10;
        if (file.size > max*1024*1024) throw new Error(`${file.name}: máximo ${max}MB`);
        const form=new FormData(); form.set("file",file); form.set("eventId",session.eventId); form.set("userId",session.userId); form.set("userName",session.userName || "Invitado"); form.set("visibility",visibility);
        await backendForm("/api/gallery/upload",form); setProgress(Math.round(((i+1)/files.length)*100));
      }
      await onUploaded();
    } catch(e) { setError(e instanceof Error ? e.message : String(e)); } finally { setBusy(false); }
  };
  return <div className="modal-backdrop" role="presentation" onMouseDown={(e) => e.target === e.currentTarget && !busy && onClose()}><section className="modal-card" role="dialog" aria-modal="true" aria-label="Subir fotos"><header><div><span className="eyebrow">GALERÍA</span><h2>Comparte tus recuerdos</h2></div><button className="icon-button" onClick={onClose} disabled={busy} aria-label="Cerrar">×</button></header><input ref={input} type="file" accept="image/jpeg,image/png,image/webp,video/mp4,video/quicktime,video/webm" multiple hidden onChange={choose}/><button className="upload-drop" onClick={() => input.current?.click()}><b>＋ Elegir fotos o videos</b><span>Fotos hasta 10MB · videos hasta 40MB</span></button>{previews.length>0&&<div className="preview-strip">{previews.map(({file,url}) => file.type.startsWith("video/")?<video key={file.name} src={url}/>:<img key={file.name} src={url} alt="Vista previa"/>)}</div>}<label className="privacy-choice">¿Quién puede verlos?<select value={visibility} onChange={(e)=>setVisibility(e.target.value)}><option value="public">Todos los invitados</option><option value="novios">Sólo los novios</option></select></label>{busy&&<div className="progress"><span style={{width:`${progress}%`}}/><b>{progress}%</b></div>}{error&&<div className="notice error">{error}</div>}<div className="modal-actions"><button className="ghost-button" onClick={onClose} disabled={busy}>Cancelar</button><button className="primary" onClick={upload} disabled={!files.length||busy}>{busy?"Subiendo…":`Subir ${files.length||""}`}</button></div></section></div>;
}

function PhotoDialog({ photo, onClose, onDeleted }: { photo: Photo; onClose: () => void; onDeleted: () => void }) {
  const { session }=useApp(); const [comments,setComments]=useState<Comment[]>([]); const [message,setMessage]=useState(""); const [error,setError]=useState(""); const [sending,setSending]=useState(false); const canDelete=session.isAdmin||session.userId===photo.userId;
  const load=()=>backend(`/api/gallery/photos/${photo.photoId}/comments`).then((x)=>setComments(Array.isArray(x)?x:[])).catch((e)=>setError(e instanceof Error?e.message:String(e)));
  useEffect(()=>{void load()},[photo.photoId]);
  const send=async()=>{if(!message.trim()||sending)return;setSending(true);try{await backend(`/api/gallery/photos/${photo.photoId}/comments`,{method:"POST",body:JSON.stringify({userId:session.userId,name:session.userName||"Invitado",message:message.trim()})});setMessage("");await load()}catch(e){setError(e instanceof Error?e.message:String(e))}finally{setSending(false)}};
  const remove=async()=>{if(!canDelete||!confirm("¿Eliminar esta foto?"))return;try{await backend(`/api/gallery/photos/${photo.photoId}`,{method:"DELETE"});await onDeleted()}catch(e){setError(e instanceof Error?e.message:String(e))}};
  const video=photo.mediaType==="video"||/\.(mp4|mov|webm)(\?|$)/i.test(photo.mediaUrl);
  return <div className="modal-backdrop dark" role="presentation"><section className="photo-dialog" role="dialog" aria-modal="true"><button className="photo-close" onClick={onClose} aria-label="Cerrar">×</button><div className="photo-stage">{video?<video src={photo.mediaUrl} controls autoPlay playsInline/>:<img src={photo.mediaUrl} alt="Foto ampliada"/>}</div><aside className="comments-panel"><div className="comments-title"><div><b>{photo.userName}</b><small>{photo.createdAt?new Date(photo.createdAt).toLocaleString("es-CL"):""}</small></div>{canDelete&&<button className="danger-link" onClick={remove}>Eliminar</button>}</div><div className="comments-list">{comments.map((c)=><div className="comment" key={c.id}><b>{c.name}</b><p>{c.message}</p></div>)}{comments.length===0&&<span className="empty-comments">Todavía no hay comentarios.</span>}</div>{error&&<div className="notice error">{error}</div>}<div className="comment-compose"><input value={message} onChange={(e)=>setMessage(e.target.value)} onKeyDown={(e)=>e.key==="Enter"&&void send()} placeholder="Escribe un comentario…"/><button onClick={send} disabled={!message.trim()||sending}>Enviar</button></div></aside></section></div>;
}
