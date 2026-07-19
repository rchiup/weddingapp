"use client";

import type { MouseEvent, ReactNode } from "react";

type Props = {
  href: string;
  className?: string;
  children: ReactNode;
};

function scrollToAnchorId(id: string) {
  const el = document.getElementById(id);
  if (!el) return;
  const reduce =
    typeof window !== "undefined" &&
    window.matchMedia("(prefers-reduced-motion: reduce)").matches;
  el.scrollIntoView({ behavior: reduce ? "auto" : "smooth", block: "start" });
}

export function InviteScrollLink({ href, className, children }: Props) {
  if (!href.startsWith("#")) {
    return (
      <a href={href} className={className}>
        {children}
      </a>
    );
  }

  const id = href.slice(1);

  return (
    <a
      href={href}
      className={className}
      onClick={(e: MouseEvent<HTMLAnchorElement>) => {
        e.preventDefault();
        scrollToAnchorId(id);
        const path = typeof window !== "undefined" ? window.location.pathname + window.location.search : "";
        window.history.replaceState(null, "", `${path}#${id}`);
      }}
    >
      {children}
    </a>
  );
}
