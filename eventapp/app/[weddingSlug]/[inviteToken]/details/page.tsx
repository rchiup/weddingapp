import Link from "next/link";
import { notFound } from "next/navigation";
import { guestChecklistPath, guestRsvpPagePath } from "@/lib/guest-urls";
import { getGuestView } from "@/lib/store/repository";
import { redirectToInviteIfRsvpPending } from "@/lib/guest-rsvp-gate";

type Props = {
  params: Promise<{ weddingSlug: string; inviteToken: string }>;
};

export default async function GuestDetailsPage({ params }: Props) {
  const { weddingSlug, inviteToken } = await params;
  const data = await getGuestView(weddingSlug, inviteToken);
  if (!data) notFound();

  redirectToInviteIfRsvpPending(weddingSlug, inviteToken, data.invite.inviteStatus);

  return (
    <main className="container-page space-y-6 pb-24">
      <div className="flex flex-wrap gap-3 text-sm">
        <Link className="font-semibold text-[var(--color-primary)] underline underline-offset-4" href={guestChecklistPath(weddingSlug, inviteToken)}>
          Volver a pendientes
        </Link>
        <Link className="text-[var(--color-muted)] underline underline-offset-4" href={guestRsvpPagePath(weddingSlug, inviteToken)}>
          Invitacion / RSVP
        </Link>
      </div>
      <section className="card space-y-2">
        <h1 className="display-title text-2xl font-semibold">Detalles del matrimonio</h1>
        <p>
          <strong>Fecha:</strong> {new Date(data.wedding.dateTime).toLocaleString("es-CL")}
        </p>
        <p>
          <strong>Ubicacion:</strong> {data.wedding.locationText}
        </p>
        {data.wedding.dressCode ? (
          <p>
            <strong>Código de vestimenta:</strong> {data.wedding.dressCode}
          </p>
        ) : null}
        <p>
          <strong>Mesa:</strong> {data.invite.tableLabel ?? "Aun no asignada"}
        </p>
        <div className="flex flex-wrap gap-2 text-sm">
          <a className="rounded-xl border border-[var(--color-border)] bg-white px-3 py-2" href={data.wedding.mapsLinks.googleMapsUrl} target="_blank" rel="noopener noreferrer">
            Abrir en Google Maps
          </a>
          <a className="rounded-xl border border-[var(--color-border)] bg-white px-3 py-2" href={data.wedding.mapsLinks.wazeUrl} target="_blank" rel="noopener noreferrer">
            Abrir en Waze
          </a>
        </div>
      </section>
    </main>
  );
}
