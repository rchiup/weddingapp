/** Fecha y hora del evento en español para copy ceremonial / planificación. */
/** Partes de la fecha para composición tipográfica en hero editorial. */
export function formatEventDateParts(dateTime: string): {
  weekday: string;
  dayMonth: string;
  year: number;
  time: string;
} {
  const d = new Date(dateTime);
  return {
    weekday: d.toLocaleDateString("es-CL", { weekday: "long" }),
    dayMonth: d.toLocaleDateString("es-CL", { day: "numeric", month: "long" }),
    year: d.getFullYear(),
    time: d.toLocaleTimeString("es-CL", { hour: "2-digit", minute: "2-digit" })
  };
}

export function formatEventDateLong(dateTime: string): string {
  return new Date(dateTime).toLocaleString("es-CL", {
    weekday: "long",
    day: "numeric",
    month: "long",
    year: "numeric",
    hour: "2-digit",
    minute: "2-digit"
  });
}

export type CountdownParts = { days: number; hours: number; minutes: number };

export function getCountdown(targetDate: string): CountdownParts {
  const now = Date.now();
  const diff = Math.max(new Date(targetDate).getTime() - now, 0);
  const day = 1000 * 60 * 60 * 24;
  const hour = 1000 * 60 * 60;
  const minute = 1000 * 60;
  return {
    days: Math.floor(diff / day),
    hours: Math.floor((diff % day) / hour),
    minutes: Math.floor((diff % hour) / minute)
  };
}

export function inviteStatusTone(status: "pending" | "confirmed" | "rejected") {
  if (status === "confirmed") return "success" as const;
  if (status === "rejected") return "danger" as const;
  return "warning" as const;
}
