"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { ElegantButton } from "@/components/ui/button";
import { ElegantCard } from "@/components/ui/card";
import { ElegantInput, ElegantTextarea } from "@/components/ui/input";
import { StatusBadge } from "@/components/ui/badge";
import { cn } from "@/components/ui/cn";
import type { Invite } from "@/types/domain";

type Props = {
  invite: Invite;
  /** Tras guardar correctamente, navegar (p. ej. volver al checklist). */
  redirectAfterSuccess?: string;
  /** default: checklist | ceremony: invitación soft | luxury: panel editorial oscuro */
  variant?: "default" | "ceremony" | "luxury";
};

type ChoiceBtnProps = {
  selected: boolean;
  onSelect: () => void;
  label: string;
  hint?: string;
  dark?: boolean;
};

function ChoiceTile({ selected, onSelect, label, hint, dark }: ChoiceBtnProps) {
  return (
    <button
      type="button"
      aria-pressed={selected}
      onClick={onSelect}
      className={cn(
        "w-full rounded-2xl border px-4 py-3.5 text-left transition",
        dark
          ? selected
            ? "border-[var(--invite-gold,#c9a962)] bg-[rgba(201,169,98,0.14)] text-stone-50 shadow-[0_0_0_1px_rgba(201,169,98,0.22)]"
            : "border-white/14 bg-white/[0.04] text-stone-200 hover:border-white/25 hover:bg-white/[0.07]"
          : selected
            ? "border-[var(--color-primary)] bg-[rgba(142,125,111,0.1)] text-[var(--color-text)]"
            : "border-[var(--color-border)] bg-white text-[var(--color-text)] hover:border-[var(--color-primary-soft)]"
      )}
    >
      <span className="block text-[0.9375rem] font-semibold leading-snug">{label}</span>
      {hint ? (
        <span
          className={cn(
            "mt-1.5 block text-[0.8125rem] leading-snug",
            dark ? "text-stone-400" : "text-[var(--color-muted)]"
          )}
        >
          {hint}
        </span>
      ) : null}
    </button>
  );
}

export function GuestRsvpForm({ invite, redirectAfterSuccess, variant = "default" }: Props) {
  const router = useRouter();
  const [status, setStatus] = useState(invite.inviteStatus);
  const [diet, setDiet] = useState(invite.dietaryRestrictions ?? "");
  /** true = «Sí», sin observaciones; false = «No», abrir campo (hay algo que indicar). */
  const [confirmsNoDietary, setConfirmsNoDietary] = useState(
    () => (invite.dietaryRestrictions?.trim() ?? "").length === 0
  );
  const [plusOneStatus, setPlusOneStatus] = useState(
    invite.plusOne.status === "not_applicable" ? "pending" : invite.plusOne.status
  );
  const [plusOneName, setPlusOneName] = useState(invite.plusOne.name ?? "");
  const [plusOneDiet, setPlusOneDiet] = useState(invite.plusOne.dietaryRestrictions ?? "");
  const [plusOneConfirmsNoDietary, setPlusOneConfirmsNoDietary] = useState(
    () => (invite.plusOne.dietaryRestrictions?.trim() ?? "").length === 0
  );
  const [message, setMessage] = useState("");
  const [messageTone, setMessageTone] = useState<"success" | "danger">("success");
  const [busy, setBusy] = useState(false);

  async function submitAll() {
    setBusy(true);
    try {
      const dietPayload = variant === "luxury" ? (confirmsNoDietary ? "" : diet.trim()) : diet;

      const mainRes = await fetch("/api/guest/rsvp", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          inviteToken: invite.token,
          inviteStatus: status,
          dietaryRestrictions: dietPayload
        })
      });

      if (!mainRes.ok) {
        setMessageTone("danger");
        setMessage("No fue posible guardar tu confirmacion.");
        return;
      }

      if (invite.plusOne.type !== "none") {
        const poDiet =
          variant === "luxury" ? (plusOneConfirmsNoDietary ? "" : plusOneDiet.trim()) : plusOneDiet;
        const plusOneRes = await fetch("/api/guest/plus-one", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({
            inviteToken: invite.token,
            status: plusOneStatus,
            name: plusOneName,
            dietaryRestrictions: poDiet
          })
        });

        if (!plusOneRes.ok) {
          setMessageTone("danger");
          setMessage("Tu confirmacion fue guardada, pero hubo un problema al guardar el +1.");
          return;
        }
      }

      setMessageTone("success");
      setMessage("Todo listo. Confirmacion guardada correctamente.");
      if (redirectAfterSuccess) {
        window.setTimeout(() => router.push(redirectAfterSuccess), 700);
      }
    } finally {
      setBusy(false);
    }
  }

  const heading =
    variant === "ceremony" || variant === "luxury"
      ? "¿Nos acompañas?"
      : "Confirmacion de asistencia";
  const sub =
    variant === "ceremony" || variant === "luxury"
      ? "Tómate un momento: tu respuesta nos ayuda a preparar todo con cariño. Incluye +1 y alergias si aplican."
      : "Responde en un solo paso tu asistencia y, si corresponde, la de tu acompanante.";

  const luxuryField =
    "invite-font-sans w-full rounded-2xl border border-white/14 bg-white/[0.06] px-4 py-3.5 text-[0.9375rem] text-stone-100 outline-none transition placeholder:text-stone-500 focus:border-[color:var(--invite-gold,#c9a962)]/55 focus:ring-2 focus:ring-[color:var(--invite-gold,#c9a962)]/22";

  if (variant === "luxury") {
    return (
      <div className="invite-rsvp-glow invite-font-sans space-y-9 rounded-[1.75rem] border border-white/11 bg-[rgba(255,252,247,0.035)] p-6 backdrop-blur-xl md:p-9">
        <div id="rsvp-main" className="scroll-mt-28 space-y-4">
          <p className="invite-eyebrow-dark">Tu asistencia</p>
          <div className="grid gap-2.5">
            <ChoiceTile
              dark
              selected={status === "confirmed"}
              onSelect={() => setStatus("confirmed")}
              label="Sí, ahí estaré"
              hint="Con mucha ilusión"
            />
            <ChoiceTile
              dark
              selected={status === "pending"}
              onSelect={() => setStatus("pending")}
              label="Aún no lo tengo claro"
              hint="Puedes volver a actualizar cuando quieras"
            />
            <ChoiceTile
              dark
              selected={status === "rejected"}
              onSelect={() => setStatus("rejected")}
              label="No podré asistir"
              hint="Lo entenderemos con cariño"
            />
          </div>
        </div>

        <div id="alergias" className="scroll-mt-28 space-y-4">
          <label className="block invite-eyebrow-dark">Alimentación</label>
          <p className="text-[0.9375rem] leading-relaxed text-stone-300">
            ¿Confirmas que{" "}
            <span className="font-medium text-stone-200">no tienes restricciones ni observaciones</span>{" "}
            sobre el banquete?
          </p>
          <div className="grid grid-cols-2 gap-3">
            <ChoiceTile
              dark
              selected={confirmsNoDietary === true}
              onSelect={() => {
                setConfirmsNoDietary(true);
                setDiet("");
              }}
              label="Sí"
              hint="Nada que indicar"
            />
            <ChoiceTile
              dark
              selected={confirmsNoDietary === false}
              onSelect={() => setConfirmsNoDietary(false)}
              label="No"
              hint="Debo indicar algo"
            />
          </div>
          {confirmsNoDietary === false ? (
            <textarea
              className={cn(luxuryField, "min-h-[6rem] resize-y")}
              value={diet}
              onChange={(e) => setDiet(e.target.value)}
              placeholder="Alergias, intolerancias, menú especial u otras observaciones"
            />
          ) : null}
        </div>

        {invite.plusOne.type !== "none" ? (
          <div
            id="plusone"
            className="scroll-mt-32 space-y-4 rounded-2xl border border-white/8 bg-white/[0.02] p-5"
          >
            <div className="flex flex-wrap items-center justify-between gap-2">
              <h3 className="text-[1rem] font-semibold tracking-wide text-white">Tu acompañante</h3>
              <span className="rounded-full border border-white/18 bg-white/[0.06] px-2.5 py-1 text-[0.65rem] font-semibold uppercase tracking-wider text-stone-300">
                {invite.plusOne.type === "nominal" ? "Nominal" : "+1"}
              </span>
            </div>
            <p className="text-[0.875rem] leading-relaxed text-stone-400">
              Confirma si asiste contigo. El nombre puede quedar pendiente.
            </p>
            <div className="grid gap-2.5">
              <ChoiceTile
                dark
                selected={plusOneStatus === "confirmed"}
                onSelect={() => setPlusOneStatus("confirmed")}
                label="Sí, asiste conmigo"
              />
              <ChoiceTile
                dark
                selected={plusOneStatus === "pending"}
                onSelect={() => setPlusOneStatus("pending")}
                label="Todavía no lo sé"
              />
              <ChoiceTile
                dark
                selected={plusOneStatus === "rejected"}
                onSelect={() => setPlusOneStatus("rejected")}
                label="No asistirá"
              />
            </div>
            <input
              type="text"
              className={luxuryField}
              placeholder="Nombre del acompañante (si lo tienes)"
              value={plusOneName}
              onChange={(e) => setPlusOneName(e.target.value)}
            />
            <div className="space-y-3 pt-1">
              <p className="text-[0.9375rem] leading-relaxed text-stone-300">
                ¿Tu acompañante confirma{" "}
                <span className="font-medium text-stone-200">sin observaciones</span> sobre el menú?
              </p>
              <div className="grid grid-cols-2 gap-3">
                <ChoiceTile
                  dark
                  selected={plusOneConfirmsNoDietary === true}
                  onSelect={() => {
                    setPlusOneConfirmsNoDietary(true);
                    setPlusOneDiet("");
                  }}
                  label="Sí"
                  hint="Nada que indicar"
                />
                <ChoiceTile
                  dark
                  selected={plusOneConfirmsNoDietary === false}
                  onSelect={() => setPlusOneConfirmsNoDietary(false)}
                  label="No"
                  hint="Debo indicar algo"
                />
              </div>
              {plusOneConfirmsNoDietary === false ? (
                <textarea
                  className={cn(luxuryField, "min-h-[5rem] resize-y")}
                  value={plusOneDiet}
                  onChange={(e) => setPlusOneDiet(e.target.value)}
                  placeholder="Observaciones alimentarias del acompañante"
                />
              ) : null}
            </div>
          </div>
        ) : null}

        <div className="space-y-4 pt-2">
          <button
            type="button"
            disabled={busy}
            onClick={submitAll}
            className="w-full rounded-2xl bg-gradient-to-b from-[#d4bc86] via-[#c9a962] to-[#a88b4a] py-4 text-[1rem] font-semibold tracking-wide text-stone-900 shadow-lg transition hover:brightness-[1.04] active:scale-[0.995] disabled:cursor-not-allowed disabled:opacity-55"
          >
            {busy ? "Enviando…" : "Guardar mi respuesta"}
          </button>
          {message ? (
            <p
              className={cn(
                "text-center text-[0.9375rem] leading-relaxed",
                messageTone === "success" ? "text-emerald-400/95" : "text-rose-400"
              )}
            >
              {message}
            </p>
          ) : null}
        </div>
      </div>
    );
  }

  return (
    <ElegantCard className="space-y-5">
      <div className="space-y-2">
        <p className="display-title text-2xl font-semibold">{heading}</p>
        <p className="text-sm text-[var(--color-muted)]">{sub}</p>
      </div>

      <div id="rsvp-main" className="scroll-mt-28 space-y-2">
        <label className="block text-sm font-medium">Tu respuesta</label>
        <select
          className="w-full rounded-xl border border-[var(--color-border)] bg-white p-2.5 text-sm outline-none transition focus:border-[var(--color-primary)] focus:ring-2 focus:ring-[rgba(142,125,111,0.18)]"
          value={status}
          onChange={(e) => setStatus(e.target.value as Invite["inviteStatus"])}
        >
          <option value="pending">Pendiente</option>
          <option value="confirmed">Confirmo</option>
          <option value="rejected">No asisto</option>
        </select>
      </div>
      <div id="alergias" className="scroll-mt-28 space-y-2">
        <label className="block text-sm font-medium">Restricciones alimentarias</label>
        <ElegantTextarea value={diet} onChange={setDiet} placeholder="Ej: vegano, alergia a frutos secos" />
      </div>

      {invite.plusOne.type !== "none" ? (
        <div id="plusone" className="scroll-mt-28 space-y-3 rounded-2xl border border-[var(--color-border)] bg-white/70 p-4">
          <div className="flex flex-wrap items-center justify-between gap-2">
            <h3 className="font-semibold">Acompanante (+1)</h3>
            <StatusBadge tone="neutral">{invite.plusOne.type === "nominal" ? "Nominal" : "Abierto"}</StatusBadge>
          </div>
          <p className="text-sm text-[var(--color-muted)]">
            El +1 confirma o rechaza explicitamente. Si todavia no tienes nombre, lo puedes dejar pendiente.
          </p>
          <select
            className="w-full rounded-xl border border-[var(--color-border)] bg-white p-2.5 text-sm outline-none transition focus:border-[var(--color-primary)] focus:ring-2 focus:ring-[rgba(142,125,111,0.18)]"
            value={plusOneStatus}
            onChange={(e) => setPlusOneStatus(e.target.value as "pending" | "confirmed" | "rejected")}
          >
            <option value="pending">Pendiente</option>
            <option value="confirmed">Confirma +1</option>
            <option value="rejected">No asiste +1</option>
          </select>
          <ElegantInput placeholder="Nombre del +1 (opcional por ahora)" value={plusOneName} onChange={setPlusOneName} />
          <ElegantInput
            placeholder="Restricciones alimentarias del +1"
            value={plusOneDiet}
            onChange={setPlusOneDiet}
          />
        </div>
      ) : null}

      <div className="flex flex-wrap items-center gap-3">
        <ElegantButton onClick={submitAll} disabled={busy}>
          {busy ? "Guardando..." : "Confirmar asistencia"}
        </ElegantButton>
        {message ? <StatusBadge tone={messageTone === "success" ? "success" : "danger"}>{message}</StatusBadge> : null}
      </div>
    </ElegantCard>
  );
}
