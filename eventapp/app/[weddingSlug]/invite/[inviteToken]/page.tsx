import { permanentRedirect } from "next/navigation";
import { guestChecklistPath } from "@/lib/guest-urls";

type Props = {
  params: Promise<{ weddingSlug: string; inviteToken: string }>;
};

/** Legado: /{slug}/invite/{token} -> /{slug}/{token} */
export default async function LegacyInviteSegmentRedirect({ params }: Props) {
  const { weddingSlug, inviteToken } = await params;
  permanentRedirect(guestChecklistPath(weddingSlug, inviteToken));
}
