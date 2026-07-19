import Link from "next/link";

export default function AdminLoginPage() {
  return (
    <main className="container-page">
      <div className="card space-y-3">
        <h1 className="text-2xl font-bold">Login organizadores</h1>
        <p className="text-sm text-neutral-700">
          Release 1 usa Firebase Auth para administradores. Esta pantalla es placeholder para el flujo real.
        </p>
        <Link className="rounded bg-black px-3 py-2 text-white inline-block" href="/admin/w_001/dashboard">
          Entrar como demo
        </Link>
      </div>
    </main>
  );
}
