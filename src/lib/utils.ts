import { clsx, type ClassValue } from "clsx";
import { twMerge } from "tailwind-merge";

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}

/** Format number in South Asian style: 1,00,000 */
export function formatBDT(n: number | null | undefined): string {
  return `BDT ${Number(n || 0).toLocaleString("en-IN")}`;
}

/** Format number only (no BDT prefix) in South Asian style */
export function formatAmount(n: number | null | undefined): string {
  return Number(n || 0).toLocaleString("en-IN");
}

/** Format tracking ID: convert legacy RK- prefix to MTH- */
export function formatTrackingId(value?: string | null): string {
  const normalized = (value || "").trim().toUpperCase();
  if (!normalized) return "";
  if (normalized.startsWith("MTH-")) return normalized;
  if (normalized.startsWith("RK-")) return `MTH-${normalized.slice(3)}`;
  return normalized;
}
