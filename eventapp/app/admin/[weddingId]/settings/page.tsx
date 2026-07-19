import { notFound } from "next/navigation";
import { getWeddingById } from "@/lib/store/repository";

type Props = {
  params: Promise<{ weddingId: string }>;
};

export default async function AdminSettingsPage({ params }: Props) {
  const { weddingId } = await params;
  const wedding = await getWeddingById(weddingId);
  if (!wedding) notFound();

  return (
    <main className="container-page space-y-4">
      <h1 className="text-2xl font-bold">Configuracion del evento</h1>
      <section className="card space-y-2">
        <p>
          <strong>Nombre:</strong> {wedding.name}
        </p>
        <p>
          <strong>Fecha:</strong> {new Date(wedding.dateTime).toLocaleString("es-CL")}
        </p>
        <p>
          <strong>Mensaje:</strong> {wedding.welcomeMessage}
        </p>
        <p>
          <strong>Ubicacion texto:</strong> {wedding.locationText}
        </p>
        <div className="flex gap-2 text-sm">
          <a className="rounded border px-2 py-1" href={wedding.mapsLinks.googleMapsUrl} target="_blank">
            Ver Google Maps
          </a>
          <a className="rounded border px-2 py-1" href={wedding.mapsLinks.wazeUrl} target="_blank">
            Ver Waze
          </a>
        </div>
      </section>
      <p className="text-sm text-neutral-700">
        En producción, esta vista debe incluir formularios para editar nombre del evento, fecha, ubicación, lista de
        regalos y mensaje inicial.
      </p>
    </main>
  );
}
