"use client";

import { useState } from "react";
import { ElegantButton } from "@/components/ui/button";
import { StatusBadge } from "@/components/ui/badge";

export function AdminWhatsappButton({ inviteToken }: { inviteToken: string }) {
  const [message, setMessage] = useState("");

  async function send() {
    const res = await fetch("/api/admin/whatsapp/send", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ inviteToken })
    });
    const json = (await res.json()) as { message?: string; error?: string };
    setMessage(json.message ?? json.error ?? "Error");
  }

  return (
    <div className="space-y-1">
      <ElegantButton className="px-3 py-1.5 text-xs" onClick={send} variant="outline">
        Enviar WhatsApp
      </ElegantButton>
      {message ? <StatusBadge tone="neutral">{message}</StatusBadge> : null}
    </div>
  );
}
