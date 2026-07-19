import { cn } from "@/components/ui/cn";

type ElegantInputProps = {
  className?: string;
  value: string;
  onChange: (value: string) => void;
  placeholder?: string;
  type?: string;
};

export function ElegantInput({ className, value, onChange, placeholder, type = "text" }: ElegantInputProps) {
  return (
    <input
      type={type}
      className={cn(
        "w-full rounded-xl border border-[var(--color-border)] bg-white px-3 py-2 text-sm outline-none transition focus:border-[var(--color-primary)] focus:ring-2 focus:ring-[rgba(142,125,111,0.18)]",
        className
      )}
      value={value}
      onChange={(event) => onChange(event.target.value)}
      placeholder={placeholder}
    />
  );
}

type ElegantTextareaProps = {
  className?: string;
  value: string;
  onChange: (value: string) => void;
  placeholder?: string;
};

export function ElegantTextarea({ className, value, onChange, placeholder }: ElegantTextareaProps) {
  return (
    <textarea
      className={cn(
        "min-h-24 w-full rounded-xl border border-[var(--color-border)] bg-white px-3 py-2 text-sm outline-none transition focus:border-[var(--color-primary)] focus:ring-2 focus:ring-[rgba(142,125,111,0.18)]",
        className
      )}
      value={value}
      onChange={(event) => onChange(event.target.value)}
      placeholder={placeholder}
    />
  );
}
