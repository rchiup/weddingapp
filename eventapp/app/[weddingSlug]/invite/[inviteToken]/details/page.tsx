import { permanentRedirect } from "next/navigation";
import { guestInviteDetailsPath } from "@/lib/guest-urls";

type Props = {
  params: Promise<{ weddingSlug: string; inviteToken: string }>;
};

export default async function LegacyNestedDetailsRedirect({ params }: Props) {
  const { weddingSlug, inviteToken } = await params;
  permanentRedirect(guestInviteDetailsPath(weddingSlug, inviteToken));
}
