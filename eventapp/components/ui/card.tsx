import { cn } from "@/components/ui/cn";

type ElegantCardProps = {
  children: React.ReactNode;
  className?: string;
  id?: string;
};

export function ElegantCard({ children, className, id }: ElegantCardProps) {
  return (
    <section
      id={id}
      className={cn(
        "rounded-2xl border border-[var(--color-border)] bg-[var(--color-ivory)] p-5 shadow-[var(--shadow-soft)]",
        className
      )}
    >
      {children}
    </section>
  );
}
