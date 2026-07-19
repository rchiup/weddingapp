import { AdminTableForm } from "@/components/admin-table-form";
import { AdminWhatsappButton } from "@/components/admin-whatsapp-button";
import { ElegantCard } from "@/components/ui/card";
import { StatusBadge } from "@/components/ui/badge";
import { guestInvitePath } from "@/lib/guest-urls";
import { getWeddingById, listWeddingInvites } from "@/lib/store/repository";
import type { Invite } from "@/types/domain";

type Props = {
  params: Promise<{ weddingId: string }>;
};

function inviteBadgeTone(status: Invite["inviteStatus"]) {
  if (status === "confirmed") return "success";
  if (status === "rejected") return "danger";
  return "warning";
}

function plusOneTone(status: Invite["plusOne"]["status"]) {
  if (status === "confirmed") return "success";
  if (status === "rejected") return "danger";
  return "neutral";
}

export default async function AdminGuestsPage({ params }: Props) {
  const { weddingId } = await params;
  const wedding = await getWeddingById(weddingId);
  const invites = await listWeddingInvites(weddingId);
  const slug = wedding?.slug ?? weddingId;

  return (
    <main className="container-page space-y-5">
      <section className="space-y-2">
        <h1 className="display-title text-4xl font-semibold">Gestion de invitados</h1>
        <p className="text-sm text-[var(--color-muted)]">
          Opera rapidamente estados, mesas y envio de invitaciones por WhatsApp.
        </p>
      </section>

      <ElegantCard className="overflow-x-auto p-0">
        <table className="w-full min-w-[920px] text-sm">
          <thead>
            <tr className="text-left text-xs uppercase tracking-[0.12em] text-[var(--color-muted)]">
              <th className="p-3">Invitado</th>
              <th className="p-3">Estado</th>
              <th className="p-3">Acompanante</th>
              <th className="p-3">Mesa</th>
              <th className="p-3">Telefono</th>
              <th className="p-3">WhatsApp</th>
            </tr>
          </thead>
          <tbody>
            {invites.map((invite: Invite) => (
              <tr key={invite.token} className="border-t border-[var(--color-border)] align-top">
                <td className="p-3">
                  <p className="font-medium">{invite.guestName}</p>
                  <p className="text-xs text-[var(--color-muted)]">{guestInvitePath(slug, invite.token)}</p>
                </td>
                <td className="p-3">
                  <StatusBadge tone={inviteBadgeTone(invite.inviteStatus)}>{invite.inviteStatus}</StatusBadge>
                </td>
                <td className="space-y-1 p-3">
                  <StatusBadge tone="neutral">{invite.plusOne.type}</StatusBadge>
                  <StatusBadge className="ml-2" tone={plusOneTone(invite.plusOne.status)}>
                    {invite.plusOne.status}
                  </StatusBadge>
                  <br />
                  <span className="text-xs text-[var(--color-muted)]">{invite.plusOne.name || "Sin nombre aun"}</span>
                </td>
                <td className="p-3">
                  <AdminTableForm inviteToken={invite.token} currentTable={invite.tableLabel} />
                </td>
                <td className="p-3 text-[var(--color-muted)]">{invite.guestPhone || "Sin telefono"}</td>
                <td className="p-3">
                  <AdminWhatsappButton inviteToken={invite.token} />
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </ElegantCard>
    </main>
  );
}
