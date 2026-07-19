import type { Invite, PlusOneType } from "@/types/domain";

/**
 * Firestore puede devolver invites con plusOne incompleto (p. ej. update que no preservó `type`).
 * Normaliza para que la UI y reglas de negocio sean fiables.
 */
export function normalizeInviteFromStorage(data: Invite, tokenFromDoc?: string): Invite {
  const po = data.plusOne;
  if (!po) {
    return {
      ...data,
      token: data.token || tokenFromDoc || "",
      plusOne: {
        type: "none",
        status: "not_applicable",
        name: "",
        dietaryRestrictions: ""
      }
    };
  }

  let type: PlusOneType = po.type;
  if (type !== "open" && type !== "nominal" && type !== "none") {
    if (po.status === "rejected" || po.status === "not_applicable") type = "none";
    else if (po.status === "pending" || po.status === "confirmed") type = "open";
    else type = "none";
  }

  return {
    ...data,
    token: data.token || tokenFromDoc || "",
    plusOne: {
      type,
      status: po.status ?? "pending",
      name: po.name ?? "",
      dietaryRestrictions: po.dietaryRestrictions ?? ""
    }
  };
}
