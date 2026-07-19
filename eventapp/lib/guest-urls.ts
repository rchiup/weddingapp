/**
 * Rutas publicas para invitados. Centralizado para WhatsApp, admin y enlaces internos.
 *
 * - Menu del evento (no personal): /{slug}
 * - Menu con contexto de invitacion: /{slug}?invite={token}
 * - Checklist / home invitado: /{slug}/{token}
 * - RSVP + info del matrimonio: /{slug}/{token}/invite
 * - Detalles (ubicacion, mesa): /{slug}/{token}/details
 *
 * Legado /{slug}/invite/{token} redirige a /{slug}/{token}
 */

export function weddingMenuPath(weddingSlug: string, inviteToken?: string) {
  const q = inviteToken ? `?invite=${encodeURIComponent(inviteToken)}` : "";
  return `/${weddingSlug}${q}`;
}

/** Home del invitado: lista de pendientes. */
export function guestChecklistPath(weddingSlug: string, inviteToken: string) {
  return `/${weddingSlug}/${encodeURIComponent(inviteToken)}`;
}

/** Pagina de invitacion: fecha, datos, confirmar o rechazar. */
export function guestRsvpPagePath(weddingSlug: string, inviteToken: string) {
  return `${guestChecklistPath(weddingSlug, inviteToken)}/invite`;
}

/** Alias: mismo que checklist (URL principal compartible). */
export function guestInvitePath(weddingSlug: string, inviteToken: string) {
  return guestChecklistPath(weddingSlug, inviteToken);
}

export function guestInviteConfirmPath(weddingSlug: string, inviteToken: string) {
  return guestRsvpPagePath(weddingSlug, inviteToken);
}

export function guestInviteDetailsPath(weddingSlug: string, inviteToken: string) {
  return `${guestChecklistPath(weddingSlug, inviteToken)}/details`;
}
