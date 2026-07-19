import { NextResponse } from "next/server";
import { updateInviteRSVP } from "@/lib/store/repository";
import { guestRsvpSchema } from "@/lib/validation/schemas";

export async function POST(request: Request) {
  const json = await request.json();
  const parsed = guestRsvpSchema.safeParse(json);
  if (!parsed.success) {
    return NextResponse.json({ error: "Payload invalido" }, { status: 400 });
  }

  const updated = await updateInviteRSVP(parsed.data.inviteToken, {
    inviteStatus: parsed.data.inviteStatus,
    dietaryRestrictions: parsed.data.dietaryRestrictions
  });
  if (!updated) {
    return NextResponse.json({ error: "Invitacion no encontrada" }, { status: 404 });
  }
  return NextResponse.json(updated);
}
