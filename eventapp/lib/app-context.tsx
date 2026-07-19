"use client";

import { createContext, useContext, useEffect, useMemo, useRef, useState } from "react";
import { resolveEventCode } from "@/lib/data";

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

type ContextValue = { session: AppSession; ready: boolean; update: (value: Partial<AppSession>) => void; join: (name: string, code: string) => Promise<void>; leave: () => void };
const AppContext = createContext<ContextValue | null>(null);

export function AppProvider({ children }: { children: React.ReactNode }) {
  const [session, setSession] = useState(empty);
  const [ready, setReady] = useState(false);
  const refreshedEvent = useRef("");
  useEffect(() => {
    const stored = localStorage.getItem(key);
    const userId = localStorage.getItem("user_id") || crypto.randomUUID();
    localStorage.setItem("user_id", userId);
    if (stored) { try { setSession({ ...empty, ...JSON.parse(stored), userId }); } catch { setSession({ ...empty, userId }); } }
    else setSession({ ...empty, userId });
    setReady(true);
  }, []);
  useEffect(() => {
    if (!ready || !session.eventId || refreshedEvent.current === session.eventId) return;
    refreshedEvent.current = session.eventId;
    resolveEventCode(session.eventId).then((event) => {
      setSession((current) => {
        if (current.eventId !== event.eventId) return current;
        const next = { ...current, eventName: event.eventName, eventDate: event.eventDate, eventActive: event.eventActive, settings: { ...defaults, ...(event.settings as Partial<EventSettings>) } };
        localStorage.setItem(key, JSON.stringify(next));
        return next;
      });
    }).catch(() => { /* conserva la sesión para que una caída temporal no expulse al invitado */ });
  }, [ready, session.eventId]);
  const persist = (next: AppSession) => { setSession(next); localStorage.setItem(key, JSON.stringify(next)); };
  const value = useMemo<ContextValue>(() => ({
    session, ready,
    update: (partial) => persist({ ...session, ...partial }),
    join: async (name, rawCode) => {
      const code = rawCode.trim().toUpperCase();
      const isAdmin = code.endsWith("-NOVIOS");
      const event = await resolveEventCode(code);
      const resolvedSettings: EventSettings = {
        ...defaults,
        ...(event.settings as Partial<EventSettings>),
      };
      persist({ ...session, userName: name.trim(), eventId: event.eventId, eventName: event.eventName, eventDate: event.eventDate, eventActive: event.eventActive, isAdmin, declinedSingleEventId: "", locationPromptedEventId: "", autoCheckinEventId: "", settings: resolvedSettings });
    },
    leave: () => persist({ ...empty, userId: session.userId }),
  }), [session, ready]);
  return <AppContext.Provider value={value}>{children}</AppContext.Provider>;
}

export function useApp() { const value = useContext(AppContext); if (!value) throw new Error("useApp fuera de AppProvider"); return value; }
