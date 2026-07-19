import { cn } from "@/components/ui/cn";

type StatusBadgeProps = {
  children: React.ReactNode;
  tone?: "neutral" | "success" | "warning" | "danger";
  className?: string;
};

export function StatusBadge({ children, tone = "neutral", className }: StatusBadgeProps) {
  const toneClass = {
    neutral: "bg-[rgba(111,106,100,0.12)] text-[var(--color-text)]",
    success: "bg-[rgba(45,122,78,0.14)] text-[#1f5e3a]",
    warning: "bg-[rgba(212,175,55,0.18)] text-[#7b5f00]",
    danger: "bg-[rgba(170,53,53,0.14)] text-[#7a2323]"
  }[tone];

  return <span className={cn("rounded-full px-2.5 py-1 text-xs font-medium", toneClass, className)}>{children}</span>;
}
