import { useLanguage } from "@/i18n/LanguageContext";
import { cn } from "@/lib/utils";

interface LanguageToggleProps {
  variant?: "default" | "compact";
  className?: string;
}

/**
 * Bilingual segmented language switch with two explicit options:
 *   বাংলা | English
 * Active language is highlighted; selection persists via LanguageProvider.
 */
const LanguageToggle = ({ variant = "default", className }: LanguageToggleProps) => {
  const { language, setLanguage } = useLanguage();

  const base =
    "inline-flex items-center rounded-md border border-border bg-background overflow-hidden select-none";
  const sizing =
    variant === "compact"
      ? "text-[11px] [&>button]:px-2 [&>button]:py-1"
      : "text-xs [&>button]:px-3 [&>button]:py-1.5";

  const btn = (active: boolean) =>
    cn(
      "font-medium transition-colors focus:outline-none focus-visible:ring-2 focus-visible:ring-primary",
      active
        ? "bg-primary text-primary-foreground"
        : "text-foreground/70 hover:bg-secondary hover:text-foreground"
    );

  return (
    <div
      className={cn(base, sizing, className)}
      role="group"
      aria-label="Language switch"
    >
      <button
        type="button"
        onClick={() => setLanguage("bn")}
        className={btn(language === "bn")}
        aria-pressed={language === "bn"}
        lang="bn"
      >
        বাংলা
      </button>
      <button
        type="button"
        onClick={() => setLanguage("en")}
        className={btn(language === "en")}
        aria-pressed={language === "en"}
        lang="en"
      >
        English
      </button>
    </div>
  );
};

export default LanguageToggle;
