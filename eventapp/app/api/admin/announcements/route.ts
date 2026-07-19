import { NextResponse } from "next/server";
import { createAnnouncement } from "@/lib/store/repository";
import { announcementSchema } from "@/lib/validation/schemas";

export async function POST(request: Request) {
  const json = await request.json();
  const parsed = announcementSchema.safeParse(json);
  if (!parsed.success) {
    return NextResponse.json({ error: "Payload invalido" }, { status: 400 });
  }

  const created = await createAnnouncement(parsed.data.weddingId, parsed.data.text, parsed.data.priority);
  return NextResponse.json(created, { status: 201 });
}
