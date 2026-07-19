import { NextResponse } from "next/server";
import { updatePlusOne } from "@/lib/store/repository";
import { plusOneSchema } from "@/lib/validation/schemas";

export async function POST(request: Request) {
  const json = await request.json();
  const parsed = plusOneSchema.safeParse(json);
  if (!parsed.success) {
    return NextResponse.json({ error: "Payload invalido" }, { status: 400 });
  }

  const updated = await updatePlusOne(parsed.data.inviteToken, {
    status: parsed.data.status,
    name: parsed.data.name,
    dietaryRestrictions: parsed.data.dietaryRestrictions
  });
  if (!updated) {
    return NextResponse.json({ error: "Invitacion no encontrada" }, { status: 404 });
  }
  return NextResponse.json(updated);
}
