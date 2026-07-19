"use client";

import { useState } from "react";
import { ElegantButton } from "@/components/ui/button";
import { ElegantInput } from "@/components/ui/input";
import { StatusBadge } from "@/components/ui/badge";

export function AdminTableForm({ inviteToken, currentTable }: { inviteToken: string; currentTable?: string }) {
  const [table, setTable] = useState(currentTable ?? "");
  const [message, setMessage] = useState("");

  async function saveTable() {
    const res = await fetch("/api/admin/guests/table", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ inviteToken, tableLabel: table })
    });
    setMessage(res.ok ? "Mesa actualizada" : "Error actualizando mesa");
  }

  return (
    <div className="space-y-2">
      <div className="flex items-center gap-2">
        <ElegantInput className="w-28" value={table} onChange={setTable} placeholder="Mesa" />
        <ElegantButton className="px-3 py-1.5 text-xs" onClick={saveTable} variant="outline">
          Guardar
        </ElegantButton>
      </div>
      {message ? <StatusBadge tone="success">{message}</StatusBadge> : null}
    </div>
  );
}
