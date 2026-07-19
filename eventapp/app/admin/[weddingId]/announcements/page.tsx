import { AdminAnnouncementForm } from "@/components/admin-announcement-form";
import { getAnnouncements } from "@/lib/store/repository";
import type { Announcement } from "@/types/domain";

type Props = {
  params: Promise<{ weddingId: string }>;
};

export default async function AdminAnnouncementsPage({ params }: Props) {
  const { weddingId } = await params;
  const feed = await getAnnouncements(weddingId);

  return (
    <main className="container-page space-y-4">
      <h1 className="text-2xl font-bold">Avisos de los novios</h1>
      <AdminAnnouncementForm weddingId={weddingId} />
      <section className="card space-y-2">
        <h2 className="text-lg font-semibold">Avisos activos</h2>
        {feed.length === 0 ? (
          <p className="text-sm text-neutral-600">No hay avisos activos.</p>
        ) : (
          <ul className="space-y-2">
            {feed.map((item: Announcement) => (
              <li key={item.id} className="rounded border p-2">
                <p className="text-xs text-neutral-500">{item.priority.toUpperCase()}</p>
                <p>{item.text}</p>
              </li>
            ))}
          </ul>
        )}
      </section>
    </main>
  );
}
