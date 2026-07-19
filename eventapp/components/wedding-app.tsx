"use client";

import Link from "next/link";
import { useRouter } from "next/navigation";
import { FormEvent, useEffect, useMemo, useState } from "react";
import { AppProvider, useApp } from "@/lib/app-context";
import { addEventDoc, backend, getEventDoc, listEventCollection, listSongs, searchGuests, setEventDoc, type RecordData } from "@/lib/data";
import { PhotoGallery } from "@/components/photo-gallery";
import { GuestOnboarding, LocationCheckinButton } from "@/components/guest-onboarding";

const menu = [
  ["Revive el momento", "/fotos", "https://images.unsplash.com/photo-1523438097201-512ae7d59c71?auto=format&fit=crop&w=1200&q=80"],
  ["Quién está acá", "/checkin", "https://images.unsplash.com/photo-1529655683826-aba9b3e77383?auto=format&fit=crop&w=1200&q=80"],
  ["Cómo llegar", "/como_llegar", "https://images.unsplash.com/photo-1524661135-423995f22d0b?auto=format&fit=crop&w=1200&q=80"],
  ["Solteros", "/solteros/chats", "https://images.unsplash.com/photo-1520034475321-cbe63696469a?auto=format&fit=crop&w=1200&q=80"],
  ["Busca tu mesa", "/mesas", "https://images.unsplash.com/photo-1529692236671-f1f6cf9683ba?auto=format&fit=crop&w=1200&q=80"],
  ["Regalos", "/lista_novios", "https://images.unsplash.com/photo-1513279922550-250c2129b13a?auto=format&fit=crop&w=1200&q=80"],
  ["Confirma tu asistencia", "/rsvp", "https://images.unsplash.com/photo-1529619768328-e3f2f8bb2f7f?auto=format&fit=crop&w=1200&q=80"],
  ["Canciones infaltables", "/songs", "https://images.unsplash.com/photo-1497032205916-ac775f0649ae?auto=format&fit=crop&w=1200&q=80"],
  ["Añadir a mi calendario", "/calendar", "https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?auto=format&fit=crop&w=1200&q=80"],
];

export function WeddingApp({ route }: { route: string }) { return <AppProvider><Route route={route} /></AppProvider>; }
function Route({ route }: { route: string }) {
  const { ready, session } = useApp();
  if (!ready) return <main className="center"><div className="loader" /></main>;
  if (route !== "entry" && route !== "event_join" && !session.eventId) return <Join />;
  if (route === "entry") return <Home />;
  if (route === "event_join") return <Join />;
  if (route === "rsvp" || route === "preferencia_menu") return <Rsvp />;
  if (route === "mesas") return <Tables />;
  if (route === "songs") return <Songs />;
  if (route === "calendar") return <Calendar />;
  if (route === "como_llegar") return <Directions />;
  if (route === "checkin") return <Checkin />;
  if (route === "fotos") return <Photos />;
  if (route === "lista_novios") return <Registry />;
  if (route === "novios_admin" || route === "admin_export") return <Admin />;
  if (route.startsWith("solteros")) return <Singles />;
  return <Home />;
}
function Page({ title, children, actions }: { title: string; children: React.ReactNode; actions?: React.ReactNode }) { return <main className="page"><header className="bar"><Link href="/entry" className="back" aria-label="Volver">←</Link><h1>{title}</h1>{actions || <span />}</header><section className="content">{children}</section></main>; }
function Notice({ children, error = false }: { children: React.ReactNode; error?: boolean }) { return <div className={error ? "notice error" : "notice"}>{children}</div>; }

function Join() {
  const { join } = useApp(); const router = useRouter(); const [name, setName] = useState(""); const [code, setCode] = useState(""); const [error, setError] = useState("");
  const submit = (e: FormEvent) => { e.preventDefault(); const normalized = code.trim().toUpperCase(); if (normalized.length < 4) return setError("Ingresa un código válido"); if (!normalized.endsWith("-NOVIOS") && name.trim().length < 2) return setError("Ingresa tu nombre"); join(name, normalized); router.push("/entry"); };
  return <main className="join"><div className="join-inner"><div className="heart">♡</div><h1>Wedding App</h1><p>Únete al evento de alguien especial</p><form className="card form" onSubmit={submit}><label>Tu nombre<input value={name} onChange={(e) => setName(e.target.value)} placeholder="Ej: María García" /></label><label>Código del evento<div className="input-row"><input value={code} onChange={(e) => setCode(e.target.value.toUpperCase())} placeholder="Ej: CAROYNONI" /><button type="button" className="paste" onClick={async () => setCode((await navigator.clipboard.readText()).toUpperCase())}>Pegar</button></div></label><small>El código te lo dieron los novios 💍</small>{error && <Notice error>{error}</Notice>}<button className="primary">Unirme al evento</button></form><small>Demo: CAROYNONI (invitado) · CAROYNONI-NOVIOS (admin)</small><a className="text-link" href="https://weddingapp-c6ix.onrender.com">Crea tu propio evento</a></div></main>;
}
function Home() {
  const { session, leave } = useApp(); const router = useRouter();
  const items = menu.filter((item) => item[1] !== "/solteros/chats" || session.isSingle);
  if (!session.eventId) return <Join />;
  return <main className="home"><GuestOnboarding/><section className="hero"><div className="hero-copy"><span className="eyebrow">BIENVENIDOS</span><h1>{session.eventName}</h1><p>{session.userName ? `Hola, ${session.userName}` : "Celebremos juntos"}</p><Countdown date={session.eventDate} /></div></section><section className="menu-grid">{items.map(([label, href, image]) => <Link href={href} className="menu-card" style={{ backgroundImage: `linear-gradient(0deg,rgba(0,0,0,.48),rgba(0,0,0,.12)),url(${image})` }} key={href}><span>{label}</span></Link>)}{session.isAdmin && <Link href="/novios_admin" className="menu-card" style={{ backgroundImage: "linear-gradient(0deg,rgba(0,0,0,.48),rgba(0,0,0,.12)),url(https://images.unsplash.com/photo-1522335789203-aabd1fc54bc9?auto=format&fit=crop&w=1200&q=80)" }}><span>Panel de novios</span></Link>}</section><footer><a href="https://weddingapp-c6ix.onrender.com" target="_blank" rel="noreferrer">Crea tu propio evento</a><button onClick={() => { leave(); router.push("/event_join"); }}>Salir del evento</button></footer></main>;
}
function Countdown({ date }: { date: string }) { const target = new Date(date).getTime(); const [now, setNow] = useState(Date.now()); useEffect(() => { const id = setInterval(() => setNow(Date.now()), 1000); return () => clearInterval(id); }, []); const days = Math.max(0, Math.ceil((target - now) / 86400000)); return <div className="countdown"><b>{days}</b><span>días para celebrar</span></div>; }

function Rsvp() {
  const { session } = useApp(); const [attending, setAttending] = useState(true); const [plusOne, setPlusOne] = useState(false); const [diet, setDiet] = useState("none"); const [allergies, setAllergies] = useState(""); const [status, setStatus] = useState("");
  useEffect(() => { getEventDoc(session.eventId, "rsvps", session.userId).then((x) => { if (!x) return; setAttending(Boolean(x.attending)); setPlusOne(Boolean(x.plus_one)); setDiet(String(x.dietary_preference || "none")); setAllergies(String(x.allergies_notes || "")); }); }, [session]);
  const save = async () => { try { await setEventDoc(session.eventId, "rsvps", session.userId, { attending, plus_one: plusOne, dietary_preference: diet, allergies: Boolean(allergies), allergies_notes: allergies, dietary_notes: "", updated_at: new Date().toISOString(), name: session.userName }); setStatus("¡Tu respuesta quedó guardada!"); } catch (e) { setStatus(String(e)); } };
  return <Page title="Confirmar asistencia"><div className="card form"><h2>¿Nos acompañas?</h2><div className="segmented"><button className={attending ? "selected" : ""} onClick={() => setAttending(true)}>Sí, asistiré</button><button className={!attending ? "selected" : ""} onClick={() => setAttending(false)}>No podré ir</button></div>{attending && <><label className="check"><input type="checkbox" checked={plusOne} onChange={(e) => setPlusOne(e.target.checked)} /> Voy con acompañante</label><label>Preferencia de menú<select value={diet} onChange={(e) => setDiet(e.target.value)}><option value="none">Sin preferencia</option><option value="vegetarian">Vegetariano</option><option value="vegan">Vegano</option></select></label><label>Alergias o comentarios<textarea value={allergies} onChange={(e) => setAllergies(e.target.value)} placeholder="Cuéntanos lo que debamos saber" /></label></>}<button className="primary" onClick={save}>Guardar respuesta</button>{status && <Notice>{status}</Notice>}</div></Page>;
}
function Tables() {
  const { session } = useApp(); const [text, setText] = useState(session.userName); const [items, setItems] = useState<RecordData[]>([]); const [loading, setLoading] = useState(false);
  const search = async () => { setLoading(true); try { setItems(await searchGuests(session.eventId, text)); } finally { setLoading(false); } };
  return <Page title="Busca tu mesa"><div className="card form"><h2>¿Dónde te sientas?</h2><p>Escribe tu nombre tal como aparece en la invitación.</p><div className="input-row"><input value={text} onChange={(e) => setText(e.target.value)} onKeyDown={(e) => e.key === "Enter" && search()} placeholder="Nombre del invitado" /><button className="primary compact" onClick={search}>{loading ? "…" : "Buscar"}</button></div></div><div className="list">{items.map((g) => <div className="card result" key={g.id}><div><b>{String(g.name || "Invitado")}</b><small>{String(g.status || "invited")}</small></div><span className="table-number">Mesa {String(g.tableNumber || "—")}</span></div>)}{!loading && items.length === 0 && <Notice>Busca un nombre para encontrar su mesa.</Notice>}</div></Page>;
}
function Songs() {
  const { session } = useApp(); const [songs, setSongs] = useState<RecordData[]>([]); const [title, setTitle] = useState(""); const [artist, setArtist] = useState(""); const [message, setMessage] = useState("");
  const load = () => listSongs(session.eventId).then(setSongs); useEffect(() => { void load(); }, [session.eventId]);
  const add = async () => { if (!title.trim()) return; try { await addEventDoc(session.eventId, "songs", { title: title.trim(), artist: artist.trim(), user_id: session.userId, user_name: session.userName, created_at: new Date().toISOString() }); setTitle(""); setArtist(""); load(); } catch (e) { setMessage(String(e)); } };
  return <Page title="Canciones infaltables"><div className="card form"><h2>¿Qué no puede faltar?</h2><label>Canción<input value={title} onChange={(e) => setTitle(e.target.value)} /></label><label>Artista<input value={artist} onChange={(e) => setArtist(e.target.value)} /></label><button className="primary" onClick={add}>Agregar canción</button>{message && <Notice error>{message}</Notice>}</div><div className="list">{songs.map((s) => <div className="card song" key={s.id}><span>♫</span><div><b>{String(s.title || "Sin título")}</b><small>{String(s.artist || "Artista desconocido")} · {String(s.user_name || "Invitado")}</small></div></div>)}</div></Page>;
}
function Calendar() { const { session } = useApp(); const start = new Date(session.eventDate || Date.now()); const end = new Date(start.getTime() + 6 * 3600000); const format = (d: Date) => d.toISOString().replace(/[-:]/g, "").replace(/\.\d{3}/, ""); const url = `https://calendar.google.com/calendar/render?action=TEMPLATE&text=${encodeURIComponent(session.eventName)}&dates=${format(start)}/${format(end)}&details=${encodeURIComponent("¡Nos vemos en la celebración!")}`; return <Page title="Añadir al calendario"><div className="card calendar-card"><div className="calendar-icon"><b>{start.getDate()}</b><span>{start.toLocaleDateString("es", { month: "short" })}</span></div><h2>{session.eventName}</h2><p>{start.toLocaleString("es-CL", { dateStyle: "full", timeStyle: "short" })}</p><a href={url} target="_blank" className="primary button-link">Añadir a Google Calendar</a></div></Page>; }

function Directions() {
  const { session } = useApp(); const [locations, setLocations] = useState<Record<string, unknown>[]>([]); const [error, setError] = useState("");
  useEffect(() => { Promise.all([backend(`/api/gallery/event/${session.eventId}/church_location`), backend(`/api/gallery/event/${session.eventId}/location`)]).then(([a,b]) => setLocations([a.location,b.location].filter(Boolean))).catch((e) => setError(String(e))); }, [session.eventId]);
  return <Page title="Cómo llegar">{error && <Notice error>No pudimos cargar la ubicación. {error}</Notice>}<div className="list">{locations.map((location, i) => { const lat = Number(location.latitude), lng = Number(location.longitude); return <div className="card destination" key={i}><span className="pin">⌖</span><div><h2>{String(location.label || (i ? "Fiesta / recepción" : "Ceremonia"))}</h2><p>{lat.toFixed(6)}, {lng.toFixed(6)}</p><a className="primary button-link" target="_blank" href={String(location.wazeUrl || `https://waze.com/ul?ll=${lat},${lng}&navigate=yes`)}>Abrir en Waze</a></div></div>; })}{!error && !locations.length && <Notice>Cargando ubicaciones…</Notice>}</div></Page>;
}
function Checkin() {
  const { session } = useApp(); const [items, setItems] = useState<RecordData[]>([]); const [query, setQuery] = useState(""); const [message, setMessage] = useState("");
  const load = () => backend(`/api/gallery/event/${session.eventId}/arrivals${query ? `?q=${encodeURIComponent(query)}` : ""}`).then((x) => setItems(x.items || [])).catch((e) => setMessage(String(e))); useEffect(() => { void load(); }, [session.eventId]);
  const arrive = async () => { try { await backend(`/api/gallery/event/${session.eventId}/checkin`, { method: "POST", body: JSON.stringify({ userId: session.userId, name: session.userName || "Invitado" }) }); setMessage("¡Llegada registrada!"); load(); } catch (e) { setMessage(String(e)); } };
  return <Page title="🎉 ¿Quién llegó?"><div className="card form"><h2>Registra tu llegada</h2><LocationCheckinButton onDone={load}/><div className="or-divider"><span>o</span></div><button className="primary" onClick={arrive}>Registrar manualmente</button>{message && <Notice>{message}</Notice>}<div className="input-row"><input value={query} onChange={(e) => setQuery(e.target.value)} placeholder="Buscar invitado" /><button className="ghost" onClick={load}>Buscar</button></div></div><div className="list">{items.map((x) => <div className="card result" key={String(x.id || x.userId)}><b>{String(x.name || "Invitado")}</b><span className="status">Llegó ✓</span></div>)}</div></Page>;
}
function Photos() { return <Page title="Revive el momento"><PhotoGallery/></Page>; }

function Registry() { const { session } = useApp(); const [url, setUrl] = useState(""); const [error, setError] = useState(""); useEffect(() => { backend(`/api/gallery/event/${session.eventId}/registry`).then((x) => setUrl(x.registryUrl || "")).catch((e) => setError(String(e))); }, [session.eventId]); return <Page title="Lista de novios"><div className="card registry"><img src="/novios_default_img.jpeg" alt="Novios" /><div><span className="eyebrow">REGALOS</span><h2>Tu presencia es nuestro mejor regalo</h2><p>Si quieres hacernos un obsequio, puedes visitar nuestra lista.</p>{url ? <a className="primary button-link" href={url} target="_blank">Ver lista de regalos</a> : <Notice>{error || "Los novios todavía no publican su lista."}</Notice>}</div></div></Page>; }

function Singles() {
  const { session, update } = useApp(); const [people, setPeople] = useState<RecordData[]>([]); const [messages, setMessages] = useState<RecordData[]>([]); const [text, setText] = useState(""); const [notice, setNotice] = useState("");
  const active = session.isSingle && session.singleEventId === session.eventId;
  const load = () => { if (!active) return; const viewerId=encodeURIComponent(session.userId); backend(`/api/solteros/event/${session.eventId}/list?viewerId=${viewerId}`).then((x) => setPeople((x.items || []).map((p:Record<string,unknown>)=>({id:String(p.userId||""),...p})))).catch((e) => setNotice(e instanceof Error?e.message:String(e))); backend(`/api/solteros/event/${session.eventId}/chat/messages?viewerId=${viewerId}`).then((x) => {setMessages(x.items || []);void backend(`/api/solteros/event/${session.eventId}/chat/read`,{method:"POST",body:JSON.stringify({viewerId:session.userId})}).catch(()=>{})}).catch((e) => setNotice(e instanceof Error?e.message:String(e))); }; useEffect(load, [active, session.eventId, session.userId]);
  const activate = async () => { try { await backend(`/api/solteros/event/${session.eventId}/activate`, { method: "POST", body: JSON.stringify({ userId: session.userId, name: session.userName }) }); update({ isSingle: true, singleEventId: session.eventId }); } catch (e) { setNotice(String(e)); } };
  const send = async () => { if (!text.trim()) return; try { await backend(`/api/solteros/event/${session.eventId}/chat/messages`, { method: "POST", body: JSON.stringify({ viewerId: session.userId, text: text.trim() }) }); setText(""); load(); } catch (e) { setNotice(e instanceof Error?e.message:String(e)); } };
  if (!active) return <Page title="Solteros"><div className="card intro"><div className="heart">♡</div><h2>Conoce a otros solteros</h2><p>Activa este espacio para conversar con otros invitados. La activación queda vinculada a este evento.</p><button className="primary" onClick={activate}>Activar Solteros</button>{notice && <Notice error>{notice}</Notice>}</div></Page>;
  return <Page title="Solteros"><div className="people-row">{people.map((p) => <div className="person" key={p.id}><span>{String(p.name || "?").slice(0,1)}</span><small>{String(p.name || "Invitado")}</small></div>)}</div><div className="card chat"><div className="messages">{messages.map((m) => <div className={String(m.userId) === session.userId ? "bubble mine" : "bubble"} key={String(m.id)}><b>{String(m.userName || m.name || "Invitado")}</b><span>{String(m.text || m.message || "")}</span></div>)}</div><div className="input-row"><input value={text} onChange={(e) => setText(e.target.value)} onKeyDown={(e) => e.key === "Enter" && send()} placeholder="Escribe un mensaje" /><button className="primary compact" onClick={send}>Enviar</button></div></div>{notice && <Notice error>{notice}</Notice>}</Page>;
}
function Admin() { const { session } = useApp(); const [guests, setGuests] = useState<RecordData[]>([]); const [rsvps, setRsvps] = useState<RecordData[]>([]); const [photos, setPhotos] = useState<RecordData[]>([]); const [status, setStatus] = useState(""); useEffect(() => { Promise.all([listEventCollection(session.eventId,"guests"),listEventCollection(session.eventId,"rsvps"),listEventCollection(session.eventId,"photos")]).then(([a,b,c]) => {setGuests(a);setRsvps(b);setPhotos(c)}).catch((e) => setStatus(String(e))); }, [session.eventId]); const exportCsv = () => { const rows = [["Nombre","Mesa","Estado"], ...guests.map((x) => [String(x.name||""),String(x.tableNumber||""),String(x.status||"")])]; const csv = rows.map((r) => r.map((x) => `"${x.replaceAll('"','""')}"`).join(",")).join("\n"); const a=document.createElement("a"); a.href=URL.createObjectURL(new Blob(["\ufeff"+csv],{type:"text/csv"})); a.download=`invitados-${session.eventId}.csv`; a.click(); };
  if (!session.isAdmin) return <Page title="Panel de novios"><Notice error>Este panel requiere ingresar con el código terminado en -NOVIOS.</Notice></Page>;
  return <Page title="Panel de novios"><div className="stats"><div className="card"><b>{guests.length}</b><span>Invitados</span></div><div className="card"><b>{rsvps.filter((x)=>x.attending).length}</b><span>Confirmados</span></div><div className="card"><b>{photos.length}</b><span>Fotos</span></div></div><div className="card admin-links"><h2>Administrar evento</h2><button onClick={exportCsv}>⇩ Exportar invitados CSV</button><Link href="/mesas">▦ Organizar mesas</Link><Link href="/checkin">✓ Ver llegadas</Link><Link href="/fotos">▧ Galería y fotos</Link></div>{status && <Notice error>{status}</Notice>}</Page>; }
