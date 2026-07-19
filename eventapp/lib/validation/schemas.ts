import { z } from "zod";

export const guestResolveSchema = z.object({
  weddingSlug: z.string().min(1),
  inviteToken: z.string().min(1)
});

export const guestRsvpSchema = z.object({
  inviteToken: z.string().min(1),
  inviteStatus: z.enum(["pending", "confirmed", "rejected"]),
  dietaryRestrictions: z.string().optional()
});

export const plusOneSchema = z.object({
  inviteToken: z.string().min(1),
  status: z.enum(["pending", "confirmed", "rejected"]),
  name: z.string().optional(),
  dietaryRestrictions: z.string().optional()
});

export const tableAssignSchema = z.object({
  inviteToken: z.string().min(1),
  tableLabel: z.string().min(1)
});

export const announcementSchema = z.object({
  weddingId: z.string().min(1),
  text: z.string().min(2),
  priority: z.enum(["normal", "high"]).default("normal")
});

export const whatsappSendSchema = z.object({
  inviteToken: z.string().min(1)
});
