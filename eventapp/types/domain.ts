export type RSVPStatus = "pending" | "confirmed" | "rejected";
export type PlusOneType = "none" | "open" | "nominal";

export type Wedding = {
  id: string;
  slug: string;
  name: string;
  dateTime: string;
  welcomeMessage: string;
  giftListUrl?: string;
  locationText: string;
  location: {
    lat: number;
    lng: number;
  };
  /** Código de vestimenta para invitados (ej. formal, cocktail) */
  dressCode?: string;
  ownerEmail: string;
};

export type Invite = {
  token: string;
  weddingId: string;
  guestName: string;
  guestPhone?: string;
  inviteStatus: RSVPStatus;
  dietaryRestrictions?: string;
  tableLabel?: string;
  plusOne: {
    type: PlusOneType;
    name?: string;
    status: RSVPStatus | "not_applicable";
    dietaryRestrictions?: string;
  };
  updatedAt: string;
};

export type Announcement = {
  id: string;
  weddingId: string;
  text: string;
  priority: "normal" | "high";
  active: boolean;
  createdAt: string;
};
