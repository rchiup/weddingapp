import { Cormorant_Garamond, Outfit } from "next/font/google";
import "./invite-theme.css";

const inviteSerif = Cormorant_Garamond({
  subsets: ["latin"],
  weight: ["300", "400", "500", "600", "700"],
  variable: "--font-invite-serif",
  display: "swap"
});

const inviteSans = Outfit({
  subsets: ["latin"],
  weight: ["300", "400", "500", "600"],
  variable: "--font-invite-sans",
  display: "swap"
});

export default function GuestInviteLayout({ children }: { children: React.ReactNode }) {
  return (
    <div className={`${inviteSerif.variable} ${inviteSans.variable} invite-experience`}>{children}</div>
  );
}
