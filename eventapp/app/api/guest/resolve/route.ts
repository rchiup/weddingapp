import { NextResponse } from "next/server";
import { getGuestView } from "@/lib/store/repository";
import { guestResolveSchema } from "@/lib/validation/schemas";

export async function POST(request: Request) {
  const json = await request.json();
  const parsed = guestResolveSchema.safeParse(json);
  if (!parsed.success) {
    return NextResponse.json({ error: "Payload invalido" }, { status: 400 });
  }

  const result = await getGuestView(parsed.data.weddingSlug, parsed.data.inviteToken);
  if (!result) {
    return NextResponse.json({ error: "Invitacion no encontrada" }, { status: 404 });
  }
  return NextResponse.json(result);
}
