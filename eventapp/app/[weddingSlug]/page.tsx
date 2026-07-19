import Image from "next/image";
import Link from "next/link";
import { notFound, redirect } from "next/navigation";
import {
  guestInviteDetailsPath,
  guestInvitePath,
  guestRsvpPagePath
} from "@/lib/guest-urls";
import { getGuestView, getWeddingBySlug } from "@/lib/store/repository";

type Props = {
  params: Promise<{ weddingSlug: string }>;
  searchParams: Promise<{ invite?: string }>;
};

function googleCalendarEventUrl(opts: {
  title: string;
  details: string;
  location: string;
  start: Date;
  hours: number;
}) {
  const fmt = (d: Date) => d.toISOString().replace(/[-:]|\.\d{3}/g, "");
  const end = new Date(opts.start.getTime() + opts.hours * 60 * 60 * 1000);
  const q = new URLSearchParams({
    action: "TEMPLATE",
    text: opts.title,
    dates: `${fmt(opts.start)}/${fmt(end)}`,
    details: opts.details,
    location: opts.location
  });
  return `https://calendar.google.com/calendar/render?${q.toString()}`;
}

type TileSpec =
  | {
      label: string;
      variant: "solid";
      href: string;
      disabled?: boolean;
    }
  | {
      label: string;
      variant: "image";
      imageUrl: string;
      href: string;
      disabled?: boolean;
    };

function MenuTile({ tile }: { tile: TileSpec }) {
  const inner = (
    <>
      {tile.variant === "image" ? (
        <div
          className="absolute inset-0 bg-cover bg-center transition duration-500 group-hover:scale-105"
          style={{ backgroundImage: `url(${tile.imageUrl})` }}
        />
      ) : (
        <div className="absolute inset-0 bg-[#2c2c2c]" />
      )}
      <div className="absolute inset-0 bg-gradient-to-t from-black/75 via-black/35 to-black/20" />
      <p className="relative z-10 px-3 text-center display-title text-sm font-semibold leading-snug text-white md:text-base">
        {tile.label}
      </p>
    </>
  );

  const shellClass =
    "group relative flex aspect-square items-center justify-center overflow-hidden rounded-3xl border border-white/10 shadow-[0_18px_40px_rgba(0,0,0,0.18)] outline-none transition focus-visible:ring-2 focus-visible:ring-[var(--color-accent)]";

  if (tile.disabled || tile.href === "#") {
    return (
      <div
        className={`${shellClass} cursor-not-allowed opacity-75`}
        title="Pronto disponible"
        role="presentation"
      >
        {inner}
      </div>
    );
  }

  return (
    <Link href={tile.href} className={`${shellClass} hover:shadow-[0_22px_50px_rgba(0,0,0,0.22)]`}>
      {inner}
    </Link>
  );
}

export default async function WeddingGuestMenuPage({ params, searchParams }: Props) {
  const { weddingSlug } = await params;
  const { invite: inviteToken } = await searchParams;

  const wedding = await getWeddingBySlug(weddingSlug);
  if (!wedding) notFound();

  if (inviteToken) {
    const guest = await getGuestView(weddingSlug, inviteToken);
    if (guest?.invite.inviteStatus === "pending") {
      redirect(guestRsvpPagePath(weddingSlug, inviteToken));
    }
  }

  const personalBase = inviteToken ? guestInvitePath(weddingSlug, inviteToken) : null;
  const maps = wedding.mapsLinks;
  const calendarHref = googleCalendarEventUrl({
    title: wedding.name,
    details: wedding.welcomeMessage,
    location: wedding.locationText,
    start: new Date(wedding.dateTime),
    hours: 4
  });

  const tiles: TileSpec[] = [
    { label: "Revive el momento", variant: "solid", href: "#", disabled: true },
    {
      label: "Quién está acá",
      variant: "image",
      imageUrl:
        "https://images.unsplash.com/photo-1519676863787-cd9a0b2d9d9b?w=800&q=80&auto=format&fit=crop",
      href: "#",
      disabled: true
    },
    {
      label: "Cómo llegar",
      variant: "image",
      imageUrl:
        "https://images.unsplash.com/photo-1524661135-423995f22d0b?w=800&q=80&auto=format&fit=crop",
      href: maps.googleMapsUrl,
      disabled: false
    },
    {
      label: "Busca tu mesa",
      variant: "image",
      imageUrl:
        "https://images.unsplash.com/photo-1414235077428-338989a2e8c0?w=800&q=80&auto=format&fit=crop",
      href: inviteToken ? guestInviteDetailsPath(weddingSlug, inviteToken) : "#",
      disabled: !personalBase
    },
    {
      label: "Regalos",
      variant: "image",
      imageUrl:
        "https://images.unsplash.com/photo-1519741497674-611481863552?w=800&q=80&auto=format&fit=crop",
      href: wedding.giftListUrl ?? "#",
      disabled: !wedding.giftListUrl
    },
    {
      label: "Confirma tu asistencia",
      variant: "solid",
      href: inviteToken ? guestRsvpPagePath(weddingSlug, inviteToken) : "#",
      disabled: !inviteToken
    },
    {
      label: "Canciones infaltables",
      variant: "image",
      imageUrl:
        "https://images.unsplash.com/photo-1520523839897-bd0b52f945a0?w=800&q=80&auto=format&fit=crop",
      href: "#",
      disabled: true
    },
    {
      label: "Añadir a mi calendario",
      variant: "image",
      imageUrl:
        "https://images.unsplash.com/photo-1464366400600-716238138c3c?w=800&q=80&auto=format&fit=crop",
      href: calendarHref,
      disabled: false
    },
    {
      label: "Avisos y novedades",
      variant: "image",
      imageUrl:
        "https://images.unsplash.com/photo-1469371670808-613ccf9d195d?w=800&q=80&auto=format&fit=crop",
      href: personalBase ? `${personalBase}#avisos` : "#",
      disabled: !personalBase
    }
  ];

  return (
    <div className="min-h-screen bg-[#f5f3ef] pb-16">
      <header className="relative mx-auto max-w-6xl px-4 pt-6 md:px-6">
        <div className="relative h-[220px] overflow-hidden rounded-3xl md:h-[300px]">
          <Image
            src="/novios_default_img.jpeg"
            alt=""
            fill
            className="object-cover object-[center_40%]"
            priority
            sizes="(max-width: 1152px) 100vw, 1152px"
          />
          <div className="absolute inset-0 bg-gradient-to-t from-black/70 via-black/30 to-black/35" />
          <div className="absolute inset-0 bg-gradient-to-r from-black/45 via-transparent to-white/25" />
          <div className="absolute inset-0 flex flex-col items-center justify-start pt-8 md:pt-10">
            <p className="text-center text-[0.7rem] font-medium uppercase tracking-[0.35em] text-white drop-shadow-[0_1px_2px_rgba(0,0,0,0.8)] md:text-xs">
              Save the date
            </p>
            <p className="mt-3 px-4 text-center display-title text-2xl font-semibold leading-tight text-white drop-shadow-[0_2px_8px_rgba(0,0,0,0.85)] md:text-4xl">
              {wedding.name}
            </p>
          </div>
        </div>
      </header>

      <main className="relative z-10 mx-auto -mt-10 max-w-lg px-4 md:max-w-3xl md:px-6 lg:max-w-4xl">
        {!inviteToken ? (
          <p className="mb-4 rounded-2xl border border-[var(--color-border)] bg-[var(--color-ivory)] px-4 py-3 text-center text-sm text-[var(--color-muted)] shadow-[var(--shadow-soft)]">
            Algunas opciones requieren tu invitacion personal. Si llegaste desde tu link, vuelve a abrir la invitacion y
            pulsa &quot;Menu del matrimonio&quot;.
          </p>
        ) : null}

        <div className="grid grid-cols-3 gap-2 sm:gap-3 md:gap-4">
          {tiles.map((tile, i) => (
            <MenuTile key={`${tile.label}-${i}`} tile={tile} />
          ))}
        </div>

        <footer className="mt-14 flex flex-col items-center gap-3 text-sm text-[var(--color-muted)]">
          <div className="flex flex-wrap items-center justify-center gap-x-6 gap-y-2">
            <Link href="/" className="inline-flex items-center gap-2 underline-offset-4 hover:underline">
              <span className="text-[var(--color-text)]">Crea tu propio evento</span>
            </Link>
            <Link
              href="/"
              className="inline-flex items-center gap-2 underline-offset-4 hover:underline"
            >
              <span className="text-[var(--color-text)]">Salir del evento</span>
            </Link>
          </div>
          {personalBase ? (
            <Link
              href={personalBase}
              className="text-xs font-semibold text-[var(--color-primary)] underline-offset-4 hover:underline"
            >
              Volver a mi invitacion
            </Link>
          ) : null}
        </footer>
      </main>
    </div>
  );
}
