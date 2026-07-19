"use client";

import { createContext, useContext, useEffect, useMemo, useState } from "react";

export type EventSettings = {
  guestsVisible: boolean; tablesVisible: boolean; singlesEnabled: boolean;
  photosEnabled: boolean; giftRegistryEnabled: boolean; giftRegistryProvider: string;
  giftRegistryCode: string; giftRegistryUrlOverride?: string | null; adminExportEnabled: boolean;
};

export type AppSession = {
  userId: string; userName: string; eventId: string; eventName: string;
  eventDate: string; eventActive: boolean; isAdmin: boolean; isSingle: boolean;
  singleEventId: string; declinedSingleEventId: string; locationPromptedEventId: string;
  autoCheckinEventId: string; settings: EventSettings;
};

const defaults: EventSettings = { guestsVisible: true, tablesVisible: true, singlesEnabled: true, photosEnabled: true, giftRegistryEnabled: true, giftRegistryProvider: "other", giftRegistryCode: "DEMO", adminExportEnabled: true };
const empty: AppSession = { userId: "", userName: "", eventId: "", eventName: "", eventDate: "", eventActive: false, isAdmin: false, isSingle: false, singleEventId: "", declinedSingleEventId: "", locationPromptedEventId: "", autoCheckinEventId: "", settings: defaults };
const key = "wedding_app_session";

type ContextValue = { session: AppSession; ready: boolean; update: (value: Partial<AppSession>) => void; join: (name: string, code: string) => void; leave: () => void };
const AppContext = createContext<ContextValue | null>(null);

export function AppProvider({ children }: { children: React.ReactNode }) {
  const [session, setSession] = useState(empty);
  const [ready, setReady] = useState(false);
  useEffect(() => {
    const stored = localStorage.getItem(key);
    const userId = localStorage.getItem("user_id") || crypto.randomUUID();
    localStorage.setItem("user_id", userId);
    if (stored) { try { setSession({ ...empty, ...JSON.parse(stored), userId }); } catch { setSession({ ...empty, userId }); } }
    else setSession({ ...empty, userId });
    setReady(true);
  }, []);
  const persist = (next: AppSession) => { setSession(next); localStorage.setItem(key, JSON.stringify(next)); };
  const value = useMemo<ContextValue>(() => ({
    session, ready,
    update: (partial) => persist({ ...session, ...partial }),
    join: (name, rawCode) => {
      const code = rawCode.trim().toUpperCase();
      const isAdmin = code.endsWith("-NOVIOS");
      const eventId = isAdmin ? code.slice(0, -7) : code;
      persist({ ...session, userName: name.trim(), eventId, eventName: `Evento ${eventId}`, eventDate: new Date().toISOString(), eventActive: true, isAdmin, declinedSingleEventId: "", locationPromptedEventId: "", autoCheckinEventId: "", settings: defaults });
    },
    leave: () => persist({ ...empty, userId: session.userId }),
  }), [session, ready]);
  return <AppContext.Provider value={value}>{children}</AppContext.Provider>;
}

export function useApp() { const value = useContext(AppContext); if (!value) throw new Error("useApp fuera de AppProvider"); return value; }
