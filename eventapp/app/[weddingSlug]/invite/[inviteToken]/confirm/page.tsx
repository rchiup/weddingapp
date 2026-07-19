import { permanentRedirect } from "next/navigation";
import { guestRsvpPagePath } from "@/lib/guest-urls";

type Props = {
  params: Promise<{ weddingSlug: string; inviteToken: string }>;
};

export default async function LegacyNestedConfirmRedirect({ params }: Props) {
  const { weddingSlug, inviteToken } = await params;
  permanentRedirect(guestRsvpPagePath(weddingSlug, inviteToken));
}
