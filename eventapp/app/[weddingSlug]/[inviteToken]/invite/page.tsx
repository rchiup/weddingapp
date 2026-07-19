import Image from "next/image";
import { notFound } from "next/navigation";
import { InviteScrollLink } from "@/components/invite-scroll-link";
import { GuestRsvpForm } from "@/components/guest-rsvp-form";
import { guestChecklistPath } from "@/lib/guest-urls";
import { formatEventDateLong, formatEventDateParts } from "@/lib/wedding-event-display";
import { coupleDisplayTitle, guestShortGreeting } from "@/lib/wedding-display";
import { getGuestView } from "@/lib/store/repository";

type Props = {
  params: Promise<{ weddingSlug: string; inviteToken: string }>;
};

function entradaCount(invite: { plusOne: { type: string } }): number {
  return invite.plusOne.type === "none" ? 1 : 2;
}

export default async function GuestRsvpInvitePage({ params }: Props) {
  const { weddingSlug, inviteToken } = await params;
  const data = await getGuestView(weddingSlug, inviteToken);
  if (!data) notFound();

  const checklistHref = guestChecklistPath(weddingSlug, inviteToken);

  const dateParts = formatEventDateParts(data.wedding.dateTime);
  const eventWhenLine = formatEventDateLong(data.wedding.dateTime);
  const coupleTitle = coupleDisplayTitle(data.wedding.name);
  const hola = guestShortGreeting(data.invite.guestName);
  const entradas = entradaCount(data.invite);
  const invitacionPalabra = entradas === 1 ? "invitación" : "invitaciones";

  const { lat, lng } = data.wedding.location;
  const mapEmbedSrc = `https://maps.google.com/maps?q=${lat},${lng}&hl=es&z=15&ie=UTF8&output=embed`;
  const googleMapsHref = `https://www.google.com/maps/search/?api=1&query=${lat},${lng}`;
  const wazeHref = `https://waze.com/ul?ll=${lat},${lng}&navigate=yes`;

  return (
    <>
      <article className="invite-experience min-h-dvh bg-[#0c0b09] text-stone-200 antialiased">
        <header className="relative min-h-[100dvh] w-full overflow-hidden">
          <div className="absolute inset-0">
            <Image
              src="/novios_default_img.jpeg"
              alt=""
              fill
              priority
              className="invite-hero-img object-cover object-[center_32%]"
              sizes="100vw"
            />
          </div>
          <div
            className="absolute inset-0 bg-gradient-to-t from-[#0c0b09] via-[#0c0b09]/48 to-[#1a1510]/58"
            aria-hidden
          />
          <div
            className="absolute inset-0 bg-gradient-to-r from-black/55 via-transparent to-amber-950/22"
            aria-hidden
          />
          <div className="pointer-events-none absolute inset-0 opacity-[0.08] invite-paper-noise" aria-hidden />

          <div className="relative z-10 mx-auto flex min-h-[100dvh] w-full max-w-6xl flex-col justify-end px-6 pb-28 pt-24 md:justify-center md:pb-24 md:pl-14 md:pr-12 lg:pl-20">
            <p className="invite-reveal invite-reveal-d1 invite-eyebrow">Invitación</p>

            <h1 className="invite-reveal invite-reveal-d2 invite-font-serif mt-6 max-w-[18ch] text-[clamp(2.35rem,7.5vw,4.5rem)] font-normal leading-[1.06] tracking-[0.01em] text-white [text-shadow:0_3px_36px_rgba(0,0,0,0.55)] md:max-w-[22ch]">
              {coupleTitle}
            </h1>

            <div className="invite-reveal invite-reveal-d3 mx-0 mt-9 max-w-md md:mx-0">
              <div className="invite-ornament-line w-28 md:w-36" />
              <div className="invite-font-serif mt-7 space-y-2 text-white">
                <p className="invite-hero-date-line capitalize text-white/95">{dateParts.weekday}</p>
                <p className="invite-hero-date-main font-medium leading-tight tracking-[0.01em] text-white">
                  {dateParts.dayMonth}
                </p>
                <p className="invite-hero-date-meta pt-1 text-white/85">
                  {dateParts.year}
                  <span className="mx-2 text-[var(--invite-champagne)]">·</span>
                  {dateParts.time}
                </p>
              </div>
            </div>

            <p className="invite-reveal invite-reveal-d4 invite-hero-greeting mt-10 max-w-xl">
              Hola,{" "}
              <span className="invite-font-serif font-semibold text-[#f0e4c8]">{hola}</span>, tenemos{" "}
              <span className="font-semibold tabular-nums text-white">{entradas}</span> {invitacionPalabra}{" "}
              para ti.
            </p>

            <div className="invite-reveal invite-reveal-d5 mt-9 flex flex-col gap-3 sm:flex-row sm:flex-wrap sm:items-center">
              <InviteScrollLink
                href="#detalles"
                className="invite-btn-secondary inline-flex min-h-[3.25rem] items-center justify-center rounded-full border border-white/25 bg-white/10 px-8 text-[0.9375rem] font-semibold text-white backdrop-blur-sm transition hover:border-white/40 hover:bg-white/[0.16]"
              >
                Ver detalles
              </InviteScrollLink>
              <InviteScrollLink
                href="#respuesta"
                className="invite-btn-primary inline-flex min-h-[3.25rem] items-center justify-center rounded-full bg-gradient-to-b from-[#d4bc86] via-[#c9a962] to-[#a88b4a] px-8 text-[0.9375rem] font-semibold text-stone-900 shadow-[0_8px_28px_rgba(0,0,0,0.35)] transition hover:brightness-[1.05]"
              >
                Confirmar
              </InviteScrollLink>
            </div>
          </div>
        </header>

        <section
          id="carta"
          className="relative scroll-mt-6 bg-[var(--invite-cream)] text-[var(--invite-ink)]"
        >
          <div
            className="pointer-events-none absolute inset-0 opacity-[0.28] invite-paper-noise mix-blend-multiply"
            aria-hidden
          />

          <div className="relative mx-auto max-w-xl px-6 py-20 md:px-10 md:py-24">
            <p className="invite-eyebrow-light text-center">Palabras de los novios</p>
            <p className="invite-font-serif mt-6 text-center text-2xl leading-none text-[#8a7038]" aria-hidden>
              ✦
            </p>
            <div className="invite-body-letter mt-10 text-center text-stone-800">{data.wedding.welcomeMessage}</div>
          </div>

          <div id="detalles" className="scroll-mt-8 border-t border-stone-400/25">
            <div className="relative mx-auto max-w-2xl px-6 py-16 md:px-10 md:py-20">
              <p className="invite-eyebrow-light text-center">Detalles del día</p>
              <h2 className="invite-font-serif mt-6 text-center text-[clamp(1.65rem,4.5vw,2rem)] font-normal tracking-[0.02em] text-stone-900">
                Ubicación y horarios
              </h2>

              <div className="mx-auto mt-10 max-w-lg space-y-5 md:max-w-xl">
                <div className="invite-detail-card">
                  <p className="invite-label-paper">Cuándo</p>
                  <p className="invite-detail-value mt-3 capitalize">{eventWhenLine}</p>
                </div>
                <div className="invite-detail-card">
                  <p className="invite-label-paper">Dónde</p>
                  <p className="invite-detail-value mt-3">{data.wedding.locationText}</p>
                </div>

                <div className="invite-detail-card">
                  <p className="invite-label-paper">Código de vestimenta</p>
                  <p className="invite-detail-value mt-3">
                    {data.wedding.dressCode?.trim() || "Te lo confirmaremos pronto."}
                  </p>
                </div>

                <div className="pt-2">
                  <p className="invite-label-paper mb-3">Cómo llegar</p>
                  <div className="invite-map-frame aspect-video w-full max-h-[min(420px,50vh)] min-h-[200px]">
                    <iframe
                      title={`Mapa: ${data.wedding.locationText}`}
                      src={mapEmbedSrc}
                      loading="lazy"
                      referrerPolicy="no-referrer-when-downgrade"
                      allowFullScreen
                    />
                  </div>
                  <div className="invite-font-sans mt-4 flex flex-wrap gap-3">
                    <a
                      href={googleMapsHref}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="guest-cta-on-dark inline-flex min-h-[2.75rem] flex-1 items-center justify-center rounded-full border border-stone-800/20 bg-stone-900 px-5 text-[0.875rem] font-semibold text-[var(--invite-cream)] transition hover:bg-stone-800 sm:flex-none"
                    >
                      Google Maps
                    </a>
                    <a
                      href={wazeHref}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="inline-flex min-h-[2.75rem] flex-1 items-center justify-center rounded-full border border-stone-500/45 bg-white px-5 text-[0.875rem] font-semibold text-stone-900 transition hover:bg-stone-50 sm:flex-none"
                    >
                      Waze
                    </a>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </section>

        <section
          id="respuesta"
          className="relative scroll-mt-6 bg-[#100e0c] pb-32 pt-20 md:pb-40 md:pt-28"
        >
          <div
            className="pointer-events-none absolute inset-0 bg-[radial-gradient(ellipse_85%_55%_at_50%_-15%,rgba(201,169,98,0.11),transparent)]"
            aria-hidden
          />
          <div className="relative mx-auto max-w-lg px-5 md:px-6">
            <div className="mb-12 text-center">
              <p className="invite-eyebrow-dark">Confirmación</p>
              <h2 className="invite-font-serif mt-5 text-[clamp(1.65rem,4.5vw,2.1rem)] font-normal leading-tight text-white">
                Sería un honor contar contigo
              </h2>
              <p className="invite-rsvp-intro mx-auto mt-5 max-w-md text-stone-300">
                Una sola respuesta basta. Si vienes con acompañante, podrás indicarlo aquí también.
              </p>
            </div>
            <GuestRsvpForm invite={data.invite} redirectAfterSuccess={checklistHref} variant="luxury" />
          </div>
        </section>
      </article>
    </>
  );
}
