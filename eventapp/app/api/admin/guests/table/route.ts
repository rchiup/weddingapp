import { NextResponse } from "next/server";
import { setTable } from "@/lib/store/repository";
import { tableAssignSchema } from "@/lib/validation/schemas";

export async function POST(request: Request) {
  const json = await request.json();
  const parsed = tableAssignSchema.safeParse(json);
  if (!parsed.success) {
    return NextResponse.json({ error: "Payload invalido" }, { status: 400 });
  }

  const updated = await setTable(parsed.data.inviteToken, parsed.data.tableLabel);
  if (!updated) {
    return NextResponse.json({ error: "Invitacion no encontrada" }, { status: 404 });
  }
  return NextResponse.json(updated);
}
