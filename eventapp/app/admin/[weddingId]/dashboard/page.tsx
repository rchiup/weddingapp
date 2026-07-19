import Link from "next/link";
import { ElegantCard } from "@/components/ui/card";
import { listWeddingInvites } from "@/lib/store/repository";
import type { Invite } from "@/types/domain";

type Props = {
  params: Promise<{ weddingId: string }>;
};

export default async function AdminDashboardPage({ params }: Props) {
  const { weddingId } = await params;
  const invites = await listWeddingInvites(weddingId);
  const confirmed = invites.filter((i: Invite) => i.inviteStatus === "confirmed").length;
  const rejected = invites.filter((i: Invite) => i.inviteStatus === "rejected").length;
  const pending = invites.filter((i: Invite) => i.inviteStatus === "pending").length;
  const total = invites.length || 1;
  const confirmedPct = Math.round((confirmed / total) * 100);
  const pendingPct = Math.round((pending / total) * 100);
  const rejectedPct = Math.round((rejected / total) * 100);

  return (
    <main className="container-page space-y-6">
      <section className="space-y-2">
        <h1 className="display-title text-4xl font-semibold">Dashboard del evento</h1>
        <p className="text-sm text-[var(--color-muted)]">Resumen de confirmaciones y accesos rapidos de operacion.</p>
      </section>

      <div className="grid gap-3 sm:grid-cols-3">
        <ElegantCard className="space-y-2">
          <p className="text-xs font-semibold uppercase tracking-[0.14em] text-[var(--color-muted)]">Confirmados</p>
          <p className="display-title text-4xl font-semibold text-[#1f5e3a]">{confirmed}</p>
          <p className="text-xs text-[var(--color-muted)]">{confirmedPct}% del total</p>
          <div className="h-2 w-full rounded-full bg-[rgba(45,122,78,0.15)]">
            <div className="h-2 rounded-full bg-[#2d7a4e]" style={{ width: `${confirmedPct}%` }} />
          </div>
        </ElegantCard>

        <ElegantCard className="space-y-2">
          <p className="text-xs font-semibold uppercase tracking-[0.14em] text-[var(--color-muted)]">Pendientes</p>
          <p className="display-title text-4xl font-semibold text-[#7b5f00]">{pending}</p>
          <p className="text-xs text-[var(--color-muted)]">{pendingPct}% del total</p>
          <div className="h-2 w-full rounded-full bg-[rgba(212,175,55,0.2)]">
            <div className="h-2 rounded-full bg-[#b88c00]" style={{ width: `${pendingPct}%` }} />
          </div>
        </ElegantCard>

        <ElegantCard className="space-y-2">
          <p className="text-xs font-semibold uppercase tracking-[0.14em] text-[var(--color-muted)]">Rechazados</p>
          <p className="display-title text-4xl font-semibold text-[#7a2323]">{rejected}</p>
          <p className="text-xs text-[var(--color-muted)]">{rejectedPct}% del total</p>
          <div className="h-2 w-full rounded-full bg-[rgba(170,53,53,0.15)]">
            <div className="h-2 rounded-full bg-[#aa3535]" style={{ width: `${rejectedPct}%` }} />
          </div>
        </ElegantCard>
      </div>

      <ElegantCard className="space-y-3">
        <h2 className="display-title text-2xl font-semibold">Navegacion admin</h2>
        <div className="grid gap-3 sm:grid-cols-2">
          <Link
            className="rounded-xl border border-[var(--color-border)] bg-white px-4 py-3 text-sm font-semibold transition hover:border-[var(--color-primary-soft)]"
            href={`/admin/${weddingId}/settings`}
          >
            Configuracion del evento
          </Link>
          <Link
            className="rounded-xl border border-[var(--color-border)] bg-white px-4 py-3 text-sm font-semibold transition hover:border-[var(--color-primary-soft)]"
            href={`/admin/${weddingId}/guests`}
          >
            Gestion de invitados
          </Link>
          <Link
            className="rounded-xl border border-[var(--color-border)] bg-white px-4 py-3 text-sm font-semibold transition hover:border-[var(--color-primary-soft)]"
            href={`/admin/${weddingId}/announcements`}
          >
            Avisos
          </Link>
          <Link
            className="rounded-xl border border-[var(--color-border)] bg-white px-4 py-3 text-sm font-semibold transition hover:border-[var(--color-primary-soft)]"
            href={`/admin/${weddingId}/messages`}
          >
            Mensajeria WhatsApp
          </Link>
        </div>
      </ElegantCard>
    </main>
  );
}
