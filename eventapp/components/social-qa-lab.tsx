"use client";

import Link from "next/link";
import { useCallback, useEffect, useMemo, useState } from "react";
import { AppProvider, useApp } from "@/lib/app-context";
import { backend, type RecordData } from "@/lib/data";

type QaState = {
  profilesActive: boolean[];
  aLikesB: boolean;
  bLikesA: boolean;
  matched: boolean;
  conversationExists: boolean;
  messageCount: number;
};

type QaMessage = RecordData & { userId: string; name: string; text: string; createdAt: string };
type QaConversation = RecordData & { otherName: string; lastMessage: string; unreadCount: number };

const emptyState: QaState = { profilesActive: [false, false], aLikesB: false, bLikesA: false, matched: false, conversationExists: false, messageCount: 0 };

export function SocialQaPage() {
  return <AppProvider><SocialQaLab /></AppProvider>;
}

function SocialQaLab() {
  const { ready, session } = useApp();
  const [runId, setRunId] = useState("");
  const [names, setNames] = useState<[string, string]>(["Vale QA", "Nico QA"]);
  const [initialized, setInitialized] = useState(false);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState("");
  const [state, setState] = useState<QaState>(emptyState);
  const [messages, setMessages] = useState<QaMessage[]>([]);
  const [conversations, setConversations] = useState<[QaConversation[], QaConversation[]]>([[], []]);
  const [potential, setPotential] = useState<[string[], string[]]>([[], []]);
  const [drafts, setDrafts] = useState<[string, string]>(["Hola desde Vale 👋", "¡Hola! Funciona desde Nico"]);
  const [activity, setActivity] = useState<string[]>([]);

  useEffect(() => {
    const saved = localStorage.getItem("wedding_social_qa_run") || crypto.randomUUID().replaceAll("-", "").slice(0, 10);
    localStorage.setItem("wedding_social_qa_run", saved);
    setRunId(saved);
  }, []);

  const eventId = session.eventId;
  const ids = useMemo<[string, string]>(() => {
    const eventPart = eventId.toLowerCase().replace(/[^a-z0-9_-]/g, "").slice(0, 18) || "event";
    return [`qa_${eventPart}_${runId}_a`, `qa_${eventPart}_${runId}_b`];
  }, [eventId, runId]);
  const addActivity = (message: string) => setActivity((current) => [`${new Date().toLocaleTimeString("es-CL", { hour: "2-digit", minute: "2-digit", second: "2-digit" })} · ${message}`, ...current].slice(0, 12));

  const refresh = useCallback(async () => {
    if (!initialized || !eventId || !runId) return;
    const query = `userA=${encodeURIComponent(ids[0])}&userB=${encodeURIComponent(ids[1])}`;
    try {
      const [qa, potentialA, potentialB, conversationA, conversationB, dm] = await Promise.all([
        backend(`/api/matches/${eventId}/qa/state?${query}`),
        backend(`/api/matches/${eventId}/potential?viewerId=${encodeURIComponent(ids[0])}`),
        backend(`/api/matches/${eventId}/potential?viewerId=${encodeURIComponent(ids[1])}`),
        backend(`/api/solteros/event/${eventId}/conversations?viewerId=${encodeURIComponent(ids[0])}`),
        backend(`/api/solteros/event/${eventId}/conversations?viewerId=${encodeURIComponent(ids[1])}`),
        backend(`/api/solteros/event/${eventId}/dm/${encodeURIComponent(ids[1])}/messages?viewerId=${encodeURIComponent(ids[0])}`),
      ]);
      setState(qa as QaState);
      setPotential([(potentialA.users || []).map((item: Record<string, unknown>) => String(item.userId)), (potentialB.users || []).map((item: Record<string, unknown>) => String(item.userId))]);
      setConversations([(conversationA.items || []) as QaConversation[], (conversationB.items || []) as QaConversation[]]);
      setMessages((dm.items || []) as QaMessage[]);
      setError("");
    } catch (reason) { setError(reason instanceof Error ? reason.message : String(reason)); }
  }, [eventId, ids, initialized, runId]);

  useEffect(() => {
    if (!initialized) return;
    void refresh();
    const timer = setInterval(() => void refresh(), 3500);
    return () => clearInterval(timer);
  }, [initialized, refresh]);

  const activateProfiles = async () => {
    if (!eventId || !runId || busy) return;
    setBusy(true); setError("");
    try {
      await Promise.all(ids.map((userId, index) => backend(`/api/solteros/event/${eventId}/activate`, { method: "POST", body: JSON.stringify({ userId, name: names[index] }) })));
      setInitialized(true); addActivity("Perfiles A y B activados en Solteros");
    } catch (reason) { setError(reason instanceof Error ? reason.message : String(reason)); }
    finally { setBusy(false); }
  };

  const like = async (actor: 0 | 1) => {
    if (busy) return; setBusy(true); setError("");
    try {
      const target = actor === 0 ? 1 : 0;
      const result = await backend(`/api/matches/${eventId}/like`, { method: "POST", body: JSON.stringify({ userId: ids[actor], targetUserId: ids[target] }) });
      addActivity(result.matched ? `🎉 ${names[actor]} dio like a ${names[target]}: MATCH` : `${names[actor]} dio like a ${names[target]}`);
      await refresh();
    } catch (reason) { setError(reason instanceof Error ? reason.message : String(reason)); }
    finally { setBusy(false); }
  };

  const send = async (actor: 0 | 1) => {
    const text = drafts[actor].trim(); if (!text || busy) return;
    const target = actor === 0 ? 1 : 0; setBusy(true); setError("");
    try {
      await backend(`/api/solteros/event/${eventId}/dm/${encodeURIComponent(ids[target])}/messages`, { method: "POST", body: JSON.stringify({ viewerId: ids[actor], text }) });
      setDrafts((current) => { const next: [string, string] = [...current]; next[actor] = ""; return next; });
      addActivity(`${names[actor]} envió: “${text}”`); await refresh();
    } catch (reason) { setError(reason instanceof Error ? reason.message : String(reason)); }
    finally { setBusy(false); }
  };

  const markRead = async (actor: 0 | 1) => {
    const target = actor === 0 ? 1 : 0; setBusy(true);
    try {
      await backend(`/api/solteros/event/${eventId}/dm/${encodeURIComponent(ids[target])}/read`, { method: "POST", body: JSON.stringify({ viewerId: ids[actor] }) });
      addActivity(`${names[actor]} marcó la conversación como leída`); await refresh();
    } catch (reason) { setError(reason instanceof Error ? reason.message : String(reason)); }
    finally { setBusy(false); }
  };

  const reset = async () => {
    if (!confirm("¿Borrar likes, match y mensajes de estos dos perfiles QA?")) return;
    setBusy(true); setError("");
    try {
      await backend(`/api/matches/${eventId}/qa/reset`, { method: "POST", body: JSON.stringify({ userIds: ids }) });
      setState(emptyState); setMessages([]); setConversations([[], []]); setPotential([[], []]); setActivity([]); setInitialized(false);
      await Promise.all(ids.map((userId, index) => backend(`/api/solteros/event/${eventId}/activate`, { method: "POST", body: JSON.stringify({ userId, name: names[index] }) })));
      setInitialized(true); addActivity("Laboratorio reiniciado y perfiles recreados");
    } catch (reason) { setError(reason instanceof Error ? reason.message : String(reason)); }
    finally { setBusy(false); }
  };

  if (!ready) return <main className="center"><div className="loader" /></main>;
  if (!session.eventId || !session.isAdmin) return <main className="qa-gate"><section className="card"><span className="eyebrow">QA LAB</span><h1>Acceso de pruebas</h1><p>Entra una sola vez con el código de novios. Dentro del laboratorio controlarás ambos perfiles sin volver a cambiar de cuenta.</p><Link className="primary button-link" href="/event_join">Entrar con código -NOVIOS</Link></section></main>;

  const steps = [state.profilesActive.every(Boolean), state.aLikesB, state.bLikesA && state.matched, state.messageCount > 0];
  return <main className="qa-lab">
    <header className="qa-header"><div><span className="eyebrow">QA LAB · {eventId}</span><h1>Matches y conversaciones</h1><p>Dos perfiles reales del backend, controlados desde esta misma pantalla.</p></div><div className="qa-header-actions"><Link href="/novios_admin" className="ghost-button">Volver</Link><button className="danger-button" onClick={reset} disabled={!initialized || busy}>Reiniciar datos QA</button></div></header>
    {error && <div className="notice error qa-error"><b>Falló una prueba:</b> {error}<button onClick={() => void refresh()}>Reintentar</button></div>}
    <section className="qa-steps">{["Activar perfiles", "A da like a B", "B devuelve el like", "Conversar"].map((label, index) => <div className={steps[index] ? "done" : index === steps.findIndex((done) => !done) ? "current" : ""} key={label}><span>{steps[index] ? "✓" : index + 1}</span><b>{label}</b></div>)}</section>
    {!initialized ? <section className="card qa-setup"><h2>Preparar los dos perfiles</h2><p>Estos nombres e IDs sólo se usan en datos con prefijo <code>qa_</code>.</p><div className="qa-name-grid"><label>Perfil A<input value={names[0]} onChange={(event) => setNames([event.target.value, names[1]])}/></label><label>Perfil B<input value={names[1]} onChange={(event) => setNames([names[0], event.target.value])}/></label></div><button className="primary" onClick={activateProfiles} disabled={busy || !runId}>{busy ? "Preparando…" : "Crear laboratorio"}</button></section> : <>
      <section className="qa-diagnostics card"><div><span className={state.profilesActive.every(Boolean) ? "ok" : ""}/><b>Perfiles</b><small>{state.profilesActive.every(Boolean) ? "A y B activos" : "incompletos"}</small></div><div><span className={potential[0].includes(ids[1]) || state.aLikesB ? "ok" : ""}/><b>Búsqueda</b><small>{potential[0].includes(ids[1]) ? "A encuentra a B" : state.aLikesB ? "B ya fue visto" : "no encontrado"}</small></div><div><span className={state.matched ? "ok" : ""}/><b>Match</b><small>{state.matched ? "recíproco" : "pendiente"}</small></div><div><span className={state.conversationExists ? "ok" : ""}/><b>Chat</b><small>{state.messageCount} mensajes</small></div></section>
      <section className="qa-dual">{([0, 1] as const).map((actor) => { const target = actor === 0 ? 1 : 0; const actorLiked = actor === 0 ? state.aLikesB : state.bLikesA; const conversation = conversations[actor][0]; return <article className={`qa-person card qa-person-${actor === 0 ? "a" : "b"}`} key={actor}><header><span className="qa-avatar">{names[actor].slice(0, 1).toUpperCase()}</span><div><small>ACTUANDO COMO PERFIL {actor === 0 ? "A" : "B"}</small><h2>{names[actor]}</h2><code>{ids[actor]}</code></div></header><div className="qa-discovery"><span>Perfil encontrado</span><b>{names[target]}</b><button className={actorLiked ? "liked" : ""} onClick={() => void like(actor)} disabled={busy || actorLiked}>{actorLiked ? "♥ Like enviado" : `♡ Dar like a ${names[target]}`}</button></div><div className="qa-conversation-status"><span>Conversación</span><b>{conversation ? conversation.lastMessage || "Match creado, sin mensajes" : "Todavía no existe"}</b>{conversation?.unreadCount > 0 && <em>{conversation.unreadCount} nuevo</em>}</div><div className="qa-phone"><div className="qa-phone-messages">{messages.map((message) => <div className={message.userId === ids[actor] ? "qa-bubble mine" : "qa-bubble"} key={message.id}><small>{message.name}</small><span>{message.text}</span></div>)}{messages.length === 0 && <p>{state.matched ? "Escribe el primer mensaje" : "Haz match para habilitar el chat"}</p>}</div><div className="qa-compose"><input value={drafts[actor]} onChange={(event) => setDrafts((current) => { const next: [string, string] = [...current]; next[actor] = event.target.value; return next; })} onKeyDown={(event) => event.key === "Enter" && void send(actor)} placeholder={`Mensaje como ${names[actor]}`} disabled={!state.matched}/><button onClick={() => void send(actor)} disabled={!state.matched || !drafts[actor].trim() || busy}>Enviar</button></div></div><button className="qa-read" onClick={() => void markRead(actor)} disabled={!state.conversationExists || busy}>Marcar leído como {names[actor]}</button></article>; })}</section>
      <section className="card qa-activity"><div><h2>Actividad de la prueba</h2><button onClick={() => void refresh()} disabled={busy}>Actualizar estado</button></div>{activity.length ? <ol>{activity.map((item) => <li key={item}>{item}</li>)}</ol> : <p>Aún no hay acciones.</p>}</section>
    </>}
  </main>;
}
