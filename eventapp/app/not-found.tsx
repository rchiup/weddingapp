import Link from "next/link";

export default function NotFound() {
  return (
    <main className="container-page">
      <div className="card space-y-2">
        <h1 className="text-2xl font-bold">No encontrado</h1>
        <p>La invitacion o recurso solicitado no existe.</p>
        <Link className="text-blue-700 underline" href="/">
          Volver al inicio
        </Link>
      </div>
    </main>
  );
}
