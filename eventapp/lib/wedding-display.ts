/** Quita prefijos tipicos para mostrar solo los nombres en titulo tipo invitacion. */
export function coupleDisplayTitle(weddingName: string): string {
  const t = weddingName.replace(/^\s*matrimonio\s+/i, "").trim();
  return t || weddingName;
}

export function guestShortGreeting(guestName: string): string {
  const first = guestName.trim().split(/\s+/)[0];
  return first || guestName;
}

export function formatISODateLocal(dateTime: string): string {
  const d = new Date(dateTime);
  const y = d.getFullYear();
  const m = String(d.getMonth() + 1).padStart(2, "0");
  const day = String(d.getDate()).padStart(2, "0");
  return `${y}-${m}-${day}`;
}
