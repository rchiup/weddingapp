import { cn } from "@/components/ui/cn";

type ElegantButtonProps = {
  children: React.ReactNode;
  className?: string;
  type?: "button" | "submit" | "reset";
  disabled?: boolean;
  onClick?: () => void;
  variant?: "primary" | "secondary" | "outline";
};

export function ElegantButton({
  children,
  className,
  type = "button",
  disabled = false,
  onClick,
  variant = "primary"
}: ElegantButtonProps) {
  const variantClassName = {
    primary: "border border-[var(--color-primary)] bg-[var(--color-primary)] text-white hover:bg-[#7d6b5d]",
    secondary: "border border-[var(--color-primary-soft)] bg-[var(--color-primary-soft)] text-[var(--color-text)] hover:bg-[#b2a38f]",
    outline:
      "border border-[var(--color-primary-soft)] bg-transparent text-[var(--color-primary)] hover:border-[var(--color-primary)] hover:bg-[rgba(188,175,158,0.12)]"
  }[variant];

  return (
    <button
      type={type}
      className={cn(
        "inline-flex items-center justify-center rounded-xl px-4 py-2 text-sm font-semibold transition disabled:cursor-not-allowed disabled:opacity-50",
        variantClassName,
        className
      )}
      onClick={onClick}
      disabled={disabled}
    >
      {children}
    </button>
  );
}
