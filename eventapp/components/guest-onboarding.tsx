"use client";

import { useEffect, useState } from "react";
import { useApp } from "@/lib/app-context";
import { backend } from "@/lib/data";

type Step = "single" | "single-list" | "location" | null;
const CHECKIN_RADIUS_METERS = 300;

function distanceMeters(aLat: number, aLng: number, bLat: number, bLng: number) {
  const r=6371000; const rad=(n:number)=>n*Math.PI/180; const dLat=rad(bLat-aLat); const dLng=rad(bLng-aLng);
  const h=Math.sin(dLat/2)**2+Math.cos(rad(aLat))*Math.cos(rad(bLat))*Math.sin(dLng/2)**2;
  return 2*r*Math.asin(Math.sqrt(h));
}

function currentPosition() {
  return new Promise<GeolocationPosition>((resolve,reject)=>navigator.geolocation.getCurrentPosition(resolve,reject,{enableHighAccuracy:true,timeout:15000,maximumAge:30000}));
}

export function GuestOnboarding() {
  const { session, update }=useApp(); const [step,setStep]=useState<Step>(null); const [busy,setBusy]=useState(false); const [error,setError]=useState(""); const [success,setSuccess]=useState("");
  const singleDecided=session.singleEventId===session.eventId||session.declinedSingleEventId===session.eventId;
  useEffect(()=>{
    if(session.isAdmin||!session.eventId||!session.userName)return;
    if(!singleDecided){setStep("single");return}
    if(session.locationPromptedEventId!==session.eventId&&session.autoCheckinEventId!==session.eventId)setStep("location");
  },[session.eventId,session.userName,session.isAdmin,singleDecided,session.locationPromptedEventId,session.autoCheckinEventId]);
  const declineSingle=()=>{update({declinedSingleEventId:session.eventId});setStep("location")};
  const activateSingle=async()=>{setBusy(true);setError("");try{await backend(`/api/solteros/event/${session.eventId}/activate`,{method:"POST",body:JSON.stringify({userId:session.userId,name:session.userName})});update({isSingle:true,singleEventId:session.eventId,declinedSingleEventId:""});setStep("location")}catch(e){setError(e instanceof Error?e.message:String(e))}finally{setBusy(false)}};
  const skipLocation=()=>{update({locationPromptedEventId:session.eventId});setStep(null)};
  const enableLocation=async()=>{
    if(!navigator.geolocation){setError("Tu navegador no permite usar ubicación.");return}
    setBusy(true);setError("");update({locationPromptedEventId:session.eventId});
    try{
      const [venue,position]=await Promise.all([backend(`/api/gallery/event/${session.eventId}/location`),currentPosition()]);
      const target=venue.location; if(!target){setSuccess("Ubicación activada. Los novios aún no configuran el lugar del evento.");setTimeout(()=>setStep(null),1600);return}
      const distance=distanceMeters(position.coords.latitude,position.coords.longitude,Number(target.latitude),Number(target.longitude));
      if(distance<=CHECKIN_RADIUS_METERS){await backend(`/api/gallery/event/${session.eventId}/checkin`,{method:"POST",body:JSON.stringify({userId:session.userId,name:session.userName||"Invitado"})});update({autoCheckinEventId:session.eventId});setSuccess("¡Llegada marcada automáticamente! ✅")}
      else setSuccess(`Ubicación activada. Estás a ${distance<1000?`${Math.round(distance)} m`:`${(distance/1000).toFixed(1)} km`} del evento.`);
      setTimeout(()=>setStep(null),1800);
    }catch(e){const geo=e as GeolocationPositionError;if(geo?.code===1)setError("No se autorizó la ubicación. Puedes activarla después desde ‘Quién está acá’.");else setError(e instanceof Error?e.message:"No pudimos obtener tu ubicación.")}
    finally{setBusy(false)}
  };
  if(!step)return null;
  return <div className="modal-backdrop onboarding" role="presentation"><section className="modal-card onboarding-card" role="dialog" aria-modal="true">
    {step==="single"&&<><div className="heart">♡</div><h2>¿Estás soltero/a?</h2><p>Esta respuesta permite mostrarte el espacio para conocer y conversar con otras personas del evento.</p><div className="choice-actions"><button onClick={declineSingle} disabled={busy}>No</button><button className="primary" onClick={()=>setStep("single-list")} disabled={busy}>Sí</button></div></>}
    {step==="single-list"&&<><div className="heart">♡</div><h2>¿Aparecer en la lista de solteros?</h2><p>Podrás ver perfiles y participar en el chat del evento. Sólo las personas que lo activen tendrán acceso.</p><div className="choice-actions"><button onClick={declineSingle} disabled={busy}>No aparecer</button><button className="primary" onClick={activateSingle} disabled={busy}>{busy?"Activando…":"Sí, activar"}</button></div></>}
    {step==="location"&&<><div className="location-icon">⌖</div><h2>Activa tu ubicación</h2><p>La usamos una sola vez para marcar tu llegada automáticamente si estás a menos de 300 metros del evento.</p><small>No guardamos tus coordenadas.</small><div className="choice-actions"><button onClick={skipLocation} disabled={busy}>Ahora no</button><button className="primary" onClick={enableLocation} disabled={busy}>{busy?"Buscando…":"Activar ubicación"}</button></div></>}
    {error&&<div className="notice error">{error}</div>}{success&&<div className="notice">{success}</div>}
  </section></div>;
}

export function LocationCheckinButton({ onDone }: { onDone?: () => void }) {
  const { session, update }=useApp(); const [busy,setBusy]=useState(false); const [message,setMessage]=useState("");
  const check=async()=>{if(!navigator.geolocation)return setMessage("Tu navegador no permite ubicación.");setBusy(true);setMessage("");try{const [venue,position]=await Promise.all([backend(`/api/gallery/event/${session.eventId}/location`),currentPosition()]);if(!venue.location)throw new Error("Los novios aún no configuran la ubicación del evento.");const distance=distanceMeters(position.coords.latitude,position.coords.longitude,Number(venue.location.latitude),Number(venue.location.longitude));if(distance>CHECKIN_RADIUS_METERS){setMessage(`Todavía estás a ${distance<1000?`${Math.round(distance)} m`:`${(distance/1000).toFixed(1)} km`} del evento.`);return}await backend(`/api/gallery/event/${session.eventId}/checkin`,{method:"POST",body:JSON.stringify({userId:session.userId,name:session.userName||"Invitado"})});update({locationPromptedEventId:session.eventId,autoCheckinEventId:session.eventId});setMessage("¡Llegada registrada con tu ubicación! ✅");onDone?.()}catch(e){const geo=e as GeolocationPositionError;setMessage(geo?.code===1?"Permiso de ubicación rechazado. Actívalo en la configuración del navegador.":e instanceof Error?e.message:String(e))}finally{setBusy(false)}};
  return <><button className="location-button" onClick={check} disabled={busy}>⌖ {busy?"Obteniendo ubicación…":"Registrar llegada con ubicación"}</button>{message&&<div className="notice">{message}</div>}</>;
}
