import { redirect } from "next/navigation";
import { guestRsvpPagePath } from "@/lib/guest-urls";

/** Solo con RSVP distinto de pendiente puede usar checklist, menú con contexto, detalles, etc. */
export function redirectToInviteIfRsvpPending(
  weddingSlug: string,
  inviteToken: string,
  inviteStatus: "pending" | "confirmed" | "rejected"
) {
  if (inviteStatus === "pending") {
    redirect(guestRsvpPagePath(weddingSlug, inviteToken));
  }
}
