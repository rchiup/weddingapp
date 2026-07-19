import type { Announcement, Invite, Wedding } from "@/types/domain";

export const mockWeddings: Wedding[] = [
  {
    id: "w_001",
    slug: "matias-cata",
    name: "Matrimonio Matias & Catalina",
    dateTime: "2026-12-12T19:00:00.000Z",
    welcomeMessage: "Nos encantaria compartir este dia contigo.",
    locationText: "Centro de Eventos El Bosque, Las Condes, Santiago",
    location: {
      lat: -33.4123,
      lng: -70.5678
    },
    dressCode:
      "Etiqueta rigurosa. Traje oscuro o smoking; vestido largo. Tonos claros opcionales para la mujer.",
    giftListUrl: "https://example.com/regalos",
    ownerEmail: "novios@eventapp.com"
  }
];

export const mockInvites: Invite[] = [
  {
    token: "inv_mn_001",
    weddingId: "w_001",
    guestName: "Matias Navarrete",
    guestPhone: "+56912345678",
    inviteStatus: "confirmed",
    dietaryRestrictions: "",
    tableLabel: "Mesa 12",
    plusOne: {
      type: "open",
      status: "pending",
      name: ""
    },
    updatedAt: new Date().toISOString()
  },
  {
    token: "inv_cp_002",
    weddingId: "w_001",
    guestName: "Catalina Perez",
    guestPhone: "+56987654321",
    inviteStatus: "confirmed",
    tableLabel: "Mesa 8",
    plusOne: {
      type: "nominal",
      status: "confirmed",
      name: "Felipe Soto"
    },
    updatedAt: new Date().toISOString()
  }
];

export const mockAnnouncements: Announcement[] = [
  {
    id: "a_1",
    weddingId: "w_001",
    text: "La ceremonia comienza puntual a las 19:00.",
    priority: "high",
    active: true,
    createdAt: new Date().toISOString()
  },
  {
    id: "a_2",
    weddingId: "w_001",
    text: "Habra transporte de regreso a las 02:00.",
    priority: "normal",
    active: true,
    createdAt: new Date().toISOString()
  }
];
