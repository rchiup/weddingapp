import { AdminWhatsappButton } from "@/components/admin-whatsapp-button";
import { listWeddingInvites } from "@/lib/store/repository";
import type { Invite } from "@/types/domain";

type Props = {
  params: Promise<{ weddingId: string }>;
};

export default async function AdminMessagesPage({ params }: Props) {
  const { weddingId } = await params;
  const invites = await listWeddingInvites(weddingId);

  return (
    <main className="container-page space-y-4">
      <h1 className="text-2xl font-bold">Mensajeria WhatsApp</h1>
      <section className="card space-y-2">
        <p className="text-sm text-neutral-700">
          Si los invitados tienen telefono registrado, puedes enviar su invitacion por WhatsApp usando la API.
        </p>
        <ul className="space-y-2">
          {invites.map((invite: Invite) => (
            <li key={invite.token} className="rounded border p-2">
              <p className="font-medium">{invite.guestName}</p>
              <p className="text-sm">{invite.guestPhone || "Sin telefono"}</p>
              <AdminWhatsappButton inviteToken={invite.token} />
            </li>
          ))}
        </ul>
      </section>
    </main>
  );
}
