import Image from "next/image";
import Link from "next/link";
import { notFound } from "next/navigation";
import { ElegantCard } from "@/components/ui/card";
import { guestRsvpPagePath } from "@/lib/guest-urls";
import { formatEventDateLong, getCountdown } from "@/lib/wedding-event-display";
import { coupleDisplayTitle, guestShortGreeting } from "@/lib/wedding-display";
import { getGuestView } from "@/lib/store/repository";
import { redirectToInviteIfRsvpPending } from "@/lib/guest-rsvp-gate";
import type { Announcement, Invite } from "@/types/domain";

type Props = {
  params: Promise<{ weddingSlug: string; inviteToken: string }>;
};

/** +1 distinto de none y no cerrado: pendiente de decisión, o confirmado pero sin nombre. */
function needsPlusOneFollowUp(invite: Invite): boolean {
  if (invite.plusOne.type === "none") return false;
  if (invite.plusOne.status === "rejected" || invite.plusOne.status === "not_applicable") {
    return false;
  }
  if (invite.plusOne.status === "pending") return true;
  if (invite.plusOne.status === "confirmed") {
    return !(invite.plusOne.name?.trim() ?? "");
  }
  return false;
}

export default async function GuestChecklistPage({ params }: Props) {
  const { weddingSlug, inviteToken } = await params;
  const data = await getGuestView(weddingSlug, inviteToken);
  if (!data) notFound();

  redirectToInviteIfRsvpPending(weddingSlug, inviteToken, data.invite.inviteStatus);

  const rsvpHref = guestRsvpPagePath(weddingSlug, inviteToken);
  const galleryHref = `/${weddingSlug}/${inviteToken}/gallery`;
  const showPlusOnePrompt = needsPlusOneFollowUp(data.invite);
  const plusOnePending = data.invite.plusOne.status === "pending";

  const coupleTitle = coupleDisplayTitle(data.wedding.name);
  const hola = guestShortGreeting(data.invite.guestName);
  const countdown = getCountdown(data.wedding.dateTime);
  const eventDateLong = formatEventDateLong(data.wedding.dateTime);

  const { lat, lng } = data.wedding.location;
  const mapEmbedSrc = `https://maps.google.com/maps?q=${lat},${lng}&hl=es&z=15&ie=UTF8&output=embed`;
  const googleMapsHref = `https://www.google.com/maps/search/?api=1&query=${lat},${lng}`;
  const wazeHref = `https://waze.com/ul?ll=${lat},${lng}&navigate=yes`;

  return (
    <>
      <article className="min-h-dvh bg-[#f5f2ed] pb-[max(1.75rem,env(safe-area-inset-bottom))] text-[#1c1916] antialiased">
        <header className="relative min-h-[17.5rem] w-full overflow-hidden md:min-h-[20rem]">
          <Image
            src="/novios_default_img.jpeg"
            alt=""
            fill
            className="object-cover object-[center_32%]"
            sizes="100vw"
            priority
          />
          <div className="absolute inset-0 bg-gradient-to-t from-black/82 via-black/45 to-black/30" />
          <div className="relative z-10 flex min-h-[17.5rem] flex-col md:min-h-[20rem]">
            <div className="flex flex-1 flex-col justify-center px-5 pb-4 pt-10 md:px-8 md:pb-5 md:pt-12">
              <p className="text-xs font-semibold uppercase tracking-[0.38em] text-[#f0e4c8] md:text-sm">
                {coupleTitle}
              </p>
              <h1 className="display-title mt-4 max-w-[16ch] text-[1.875rem] font-normal leading-[1.12] text-white md:max-w-none md:text-[2.5rem]">
                Hola, {hola}
              </h1>
              <p className="mt-4 max-w-md text-base leading-relaxed text-white/90 md:text-lg">
                Aquí tienes la información del evento y todo lo que necesitas saber.
              </p>
            </div>

            <div className="mt-auto px-4 pb-5 md:px-8 md:pb-6">
              <div className="mx-auto max-w-lg rounded-3xl border border-white/20 bg-black/45 px-4 py-5 backdrop-blur-lg md:px-6 md:py-6">
                <p className="text-center text-xs font-semibold uppercase tracking-[0.28em] text-[#e8d5b4]">
                  Falta para el gran día
                </p>
                <p className="mt-2 text-center text-sm font-medium capitalize leading-snug text-white md:text-base">
                  {eventDateLong}
                </p>
                <div className="mt-5 grid grid-cols-3 divide-x divide-white/20">
                  <div className="px-2 py-1 text-center first:pl-0 last:pr-0">
                    <p className="display-title text-3xl font-semibold tabular-nums text-white md:text-4xl">
                      {countdown.days}
                    </p>
                    <p className="mt-1 text-xs font-semibold uppercase tracking-[0.14em] text-white/75">
                      Días
                    </p>
                  </div>
                  <div className="px-2 py-1 text-center">
                    <p className="display-title text-3xl font-semibold tabular-nums text-white md:text-4xl">
                      {countdown.hours}
                    </p>
                    <p className="mt-1 text-xs font-semibold uppercase tracking-[0.14em] text-white/75">
                      Horas
                    </p>
                  </div>
                  <div className="px-2 py-1 text-center">
                    <p className="display-title text-3xl font-semibold tabular-nums text-white md:text-4xl">
                      {countdown.minutes}
                    </p>
                    <p className="mt-1 text-xs font-semibold uppercase tracking-[0.14em] text-white/75">
                      Minutos
                    </p>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </header>

        <div className="mx-auto max-w-xl px-5 pt-10 md:px-8 md:pt-12">
          {showPlusOnePrompt ? (
            <ElegantCard className="mb-12 border-[#c9a962]/35 bg-white p-6 shadow-[0_4px_24px_rgba(28,25,22,0.07)] ring-1 ring-[#c9a962]/15 md:p-7">
              <span className="inline-block rounded-full bg-[rgba(201,169,98,0.2)] px-3 py-1 text-xs font-semibold uppercase tracking-wider text-[#5c4a1a]">
                {plusOnePending ? "Pendiente" : "Falta un dato"}
              </span>
              <h2 className="display-title mt-4 text-xl font-semibold text-[#1c1916] md:text-2xl">
                Tu acompañante (+1)
              </h2>
              <p className="mt-3 text-base leading-relaxed text-[#5c534a] md:text-lg">
                {plusOnePending
                  ? "En tu invitación indica si tu acompañante asiste. Si confirmas que sí, podrás agregar su nombre u otros datos."
                  : "Tu acompañante está confirmado. Falta su nombre para mesa y protocolo."}
              </p>
              <Link
                href={`${rsvpHref}#plusone`}
                className="guest-cta-on-dark mt-6 flex min-h-[3rem] w-full items-center justify-center rounded-full bg-[#1c1916] text-base font-semibold text-[#f5f2ed] transition hover:bg-[#2e2924]"
              >
                {plusOnePending ? "Completar en invitación" : "Agregar nombre"}
              </Link>
            </ElegantCard>
          ) : null}

          <section id="info-dia" className={`scroll-mt-28 ${showPlusOnePrompt ? "" : "mt-2"} border-t border-[#d8d2c8] pt-14`}>
            <div className="text-center">
              <p className="text-xs font-semibold uppercase tracking-[0.32em] text-[#454039] md:text-sm">
                Información práctica
              </p>
              <h2 className="display-title mt-3 text-2xl font-semibold text-[#1c1916] md:text-[1.65rem]">
                Tu mesa y cómo llegar
              </h2>
            </div>

            <div className="mt-10 space-y-5">
              {data.wedding.dressCode ? (
                <ElegantCard className="border-[#e0d9cf] bg-white p-6 shadow-[0_2px_20px_rgba(28,25,22,0.06)] md:p-7">
                  <p className="text-xs font-semibold uppercase tracking-[0.26em] text-[#454039]">
                    Código de vestimenta
                  </p>
                  <p className="mt-3 text-base leading-relaxed text-[#2c2825] md:text-lg">
                    {data.wedding.dressCode}
                  </p>
                </ElegantCard>
              ) : null}

              <ElegantCard className="border-[#e0d9cf] bg-white p-6 shadow-[0_2px_20px_rgba(28,25,22,0.06)] md:p-7">
                <p className="text-xs font-semibold uppercase tracking-[0.26em] text-[#454039]">Mesa</p>
                <p className="display-title mt-3 text-xl text-[#1c1916] md:text-2xl">
                  {data.invite.tableLabel ?? "Te la asignaremos pronto"}
                </p>
              </ElegantCard>

              <ElegantCard className="border-[#e0d9cf] bg-white p-6 shadow-[0_2px_20px_rgba(28,25,22,0.06)] md:p-7">
                <p className="text-xs font-semibold uppercase tracking-[0.26em] text-[#454039]">Lugar</p>
                <p className="mt-3 text-base leading-relaxed text-[#2c2825] md:text-lg">{data.wedding.locationText}</p>
                <p className="mt-6 text-xs font-semibold uppercase tracking-[0.26em] text-[#454039]">Mapa</p>
                <div className="relative mt-4 aspect-video w-full overflow-hidden rounded-2xl border border-[#e0d9cf] bg-[#e8e4dc]">
                  <iframe
                    title={`Mapa: ${data.wedding.locationText}`}
                    src={mapEmbedSrc}
                    loading="lazy"
                    referrerPolicy="no-referrer-when-downgrade"
                    allowFullScreen
                    className="absolute inset-0 h-full w-full border-0"
                  />
                </div>
                <div className="mt-5 flex flex-col gap-3 sm:flex-row">
                  <a
                    href={googleMapsHref}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="guest-cta-on-dark inline-flex min-h-[3rem] flex-1 items-center justify-center rounded-full bg-[#1c1916] px-5 text-base font-semibold text-[#f5f2ed] transition hover:bg-[#2e2924]"
                  >
                    Google Maps
                  </a>
                  <a
                    href={wazeHref}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="inline-flex min-h-[3rem] flex-1 items-center justify-center rounded-full border-2 border-[#c4b8a8] bg-white px-5 text-base font-semibold text-[#1c1916] transition hover:bg-[#faf8f5]"
                  >
                    Waze
                  </a>
                </div>
              </ElegantCard>
            </div>
          </section>

          <ElegantCard
            id="avisos"
            className="scroll-mt-28 mb-12 mt-14 border-[#e0d9cf] bg-white p-6 shadow-[0_2px_20px_rgba(28,25,22,0.06)] md:p-7"
          >
            <p className="text-xs font-semibold uppercase tracking-[0.26em] text-[#454039]">Novios</p>
            <h2 className="display-title mt-2 text-xl font-semibold text-[#1c1916] md:text-2xl">Avisos</h2>
            {data.announcements.length === 0 ? (
              <p className="mt-4 text-base text-[#6f6a64]">No hay avisos por ahora.</p>
            ) : (
              <ul className="mt-6 space-y-4">
                {data.announcements.map((announcement: Announcement) => (
                  <li
                    key={announcement.id}
                    className="rounded-2xl border border-[#ebe6df] bg-[#faf9f6] p-4 md:p-5"
                  >
                    <p className="text-xs font-semibold uppercase tracking-[0.15em] text-[#6f6a64]">
                      {announcement.priority === "high" ? "Importante" : "Aviso"}
                    </p>
                    <p className="mt-2 text-base leading-relaxed text-[#2c2825]">{announcement.text}</p>
                  </li>
                ))}
              </ul>
            )}
          </ElegantCard>

          <ElegantCard className="mb-14 border-[#e0d9cf] bg-white p-6 shadow-[0_2px_20px_rgba(28,25,22,0.06)] md:p-7">
            <p className="text-xs font-semibold uppercase tracking-[0.26em] text-[#454039]">Galería</p>
            <h2 className="display-title mt-2 text-xl font-semibold text-[#1c1916] md:text-2xl">
              Fotos del evento
            </h2>
            <p className="mt-4 text-base text-[#6f6a64]">
              Sube y revisa fotos en la galería. Versión mock lista para conectar a Firebase.
            </p>
            <Link
              href={galleryHref}
              className="guest-cta-on-dark mt-6 flex min-h-[3rem] w-full items-center justify-center rounded-full bg-[#1c1916] text-base font-semibold text-[#f5f2ed] transition hover:bg-[#2e2924]"
            >
              Ir a la galería
            </Link>
          </ElegantCard>
        </div>
      </article>
    </>
  );
}
