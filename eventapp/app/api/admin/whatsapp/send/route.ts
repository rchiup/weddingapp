import { NextResponse } from "next/server";
import { sendInvitationWhatsApp } from "@/lib/services/whatsapp";
import { getInviteByToken, getWeddingBySlug } from "@/lib/store/repository";
import { whatsappSendSchema } from "@/lib/validation/schemas";

export async function POST(request: Request) {
  const json = await request.json();
  const parsed = whatsappSendSchema.safeParse(json);
  if (!parsed.success) {
    return NextResponse.json({ error: "Payload invalido" }, { status: 400 });
  }

  const invite = await getInviteByToken(parsed.data.inviteToken);
  if (!invite) {
    return NextResponse.json({ error: "Invitacion no encontrada" }, { status: 404 });
  }

  const wedding = await getWeddingBySlug("matias-cata");
  if (!wedding) {
    return NextResponse.json({ error: "Boda no encontrada" }, { status: 404 });
  }

  const sent = await sendInvitationWhatsApp({
    weddingSlug: wedding.slug,
    inviteToken: invite.token
  });

  return NextResponse.json(sent, { status: sent.ok ? 200 : 400 });
}
