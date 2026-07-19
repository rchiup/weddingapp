import { guestChecklistPath } from "@/lib/guest-urls";
import { getInviteByToken, getWeddingBySlug } from "@/lib/store/repository";

type SendResult = {
  ok: boolean;
  message: string;
};

// Minimal provider abstraction. In production this should call Meta or Twilio API.
export async function sendInvitationWhatsApp(params: {
  weddingSlug: string;
  inviteToken: string;
}): Promise<SendResult> {
  const invite = await getInviteByToken(params.inviteToken);
  if (!invite) {
    return { ok: false, message: "Invitacion no encontrada" };
  }
  if (!invite.guestPhone) {
    return { ok: false, message: "El invitado no tiene telefono registrado" };
  }
  const wedding = await getWeddingBySlug(params.weddingSlug);
  if (!wedding) {
    return { ok: false, message: "Boda no encontrada" };
  }

  const base = (process.env.NEXT_PUBLIC_APP_URL ?? "http://localhost:3000").replace(/\/$/, "");
  const invitationUrl = `${base}${guestChecklistPath(wedding.slug, invite.token)}`;
  const body = `Hola ${invite.guestName}, estas invitado/a a ${wedding.name}. Confirma aqui: ${invitationUrl}`;

  // Placeholder integration for Release 1 local development.
  // A real adapter should use WHATSAPP_PROVIDER envs and call external API.
  console.info("[WHATSAPP_MOCK_SEND]", {
    to: invite.guestPhone,
    message: body
  });

  return { ok: true, message: "Mensaje enviado (modo mock)" };
}
