"use client";

import { useState } from "react";

export function AdminAnnouncementForm({ weddingId }: { weddingId: string }) {
  const [text, setText] = useState("");
  const [priority, setPriority] = useState<"normal" | "high">("normal");
  const [message, setMessage] = useState("");

  async function createAnnouncement() {
    const res = await fetch("/api/admin/announcements", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ weddingId, text, priority })
    });
    setMessage(res.ok ? "Aviso creado" : "No fue posible crear aviso");
    if (res.ok) {
      setText("");
      setPriority("normal");
    }
  }

  return (
    <div className="card space-y-2">
      <h2 className="text-lg font-semibold">Crear aviso</h2>
      <textarea
        className="w-full rounded border p-2"
        value={text}
        onChange={(e) => setText(e.target.value)}
        placeholder="Escribe el aviso para todos los invitados"
      />
      <select className="rounded border p-2" value={priority} onChange={(e) => setPriority(e.target.value as "normal" | "high")}>
        <option value="normal">Normal</option>
        <option value="high">Alta prioridad</option>
      </select>
      <button className="rounded bg-black px-3 py-2 text-white" onClick={createAnnouncement}>
        Publicar aviso
      </button>
      {message ? <p className="text-sm text-green-700">{message}</p> : null}
    </div>
  );
}
