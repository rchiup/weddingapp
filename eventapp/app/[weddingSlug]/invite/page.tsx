import Link from "next/link";
import { notFound } from "next/navigation";
import { ElegantCard } from "@/components/ui/card";
import { getWeddingBySlug } from "@/lib/store/repository";
import { weddingMenuPath } from "@/lib/guest-urls";

type Props = {
  params: Promise<{ weddingSlug: string }>;
};

export default async function InviteHubPage({ params }: Props) {
  const { weddingSlug } = await params;
  const wedding = await getWeddingBySlug(weddingSlug);
  if (!wedding) notFound();

  return (
    <main className="container-page max-w-lg space-y-6 py-12">
      <ElegantCard className="space-y-3 text-center">
        <p className="text-xs font-semibold uppercase tracking-[0.2em] text-[var(--color-muted)]">Invitacion</p>
        <h1 className="display-title text-3xl font-semibold">{wedding.name}</h1>
        <p className="text-sm text-[var(--color-muted)]">
          Tu enlace personal se ve como <strong>/{weddingSlug}/tu-codigo</strong> (lista de pendientes) o con{" "}
          <strong>/invite</strong> al final para la pagina de confirmacion. Abre siempre el enlace completo que te
          enviaron.
        </p>
        <Link
          className="inline-block text-sm font-semibold text-[var(--color-primary)] underline underline-offset-4"
          href={weddingMenuPath(weddingSlug)}
        >
          Ir al menu del evento
        </Link>
      </ElegantCard>
    </main>
  );
}
