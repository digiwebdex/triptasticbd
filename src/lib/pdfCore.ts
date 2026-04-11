/**
 * pdfCore.ts — Unified PDF Design System for Manasik Travel Hub
 * 
 * Provides reusable, branded PDF components for all document types:
 * Headers, footers, summary cards, title blocks, page numbering,
 * filter summaries, and status badges.
 */
import jsPDF from "jspdf";
import autoTable from "jspdf-autotable";
import QRCode from "qrcode";
import logoImg from "@/assets/logo-pdf.png";
import { getSignatureData, type SignatureData } from "./pdfSignature";
import { registerBengaliFont, addBengaliText, hasBengali, bengaliCellHook } from "./pdfFontLoader";
import { getPdfCompanyConfig, type PdfCompanyConfig } from "./pdfCompanyConfig";
import { formatBDT, formatAmount } from "@/lib/utils";

// ═══════════════════════════════════════════════════════════════
// BRAND CONSTANTS
// ═══════════════════════════════════════════════════════════════
export const GOLD = { r: 197, g: 165, b: 90 };
export const DARK = { r: 35, g: 40, b: 48 };
export const LIGHT_BG = { r: 250, g: 249, b: 247 };
export const MUTED = { r: 120, g: 120, b: 120 };
export const ORANGE = { r: 234, g: 160, b: 45 }; // matches logo plane color

export const FOOTER_HEIGHT = 14;
const CONTENT_BOTTOM_PADDING = 4;
const CONTINUATION_START_Y = 18;

// ═══════════════════════════════════════════════════════════════
// HELPERS
// ═══════════════════════════════════════════════════════════════
export const fmtDate = (d: string | null | undefined) =>
  d ? new Date(d).toLocaleDateString("en-GB", { day: "2-digit", month: "short", year: "numeric" }) : "—";

export const fmtDateTime = (d: string | null | undefined) =>
  d ? new Date(d).toLocaleDateString("en-GB", { day: "2-digit", month: "short", year: "numeric", hour: "2-digit", minute: "2-digit" }) : "—";

export const fmtAmount = (value: number) => {
  const n = Number(value || 0);
  return n.toLocaleString("en-IN", {
    minimumFractionDigits: Number.isInteger(n) ? 0 : 2,
    maximumFractionDigits: 2,
  });
};

export const fmtBDT = (value: number) => `BDT ${fmtAmount(value)}`;

export function getContentBottomY(doc: jsPDF): number {
  return doc.internal.pageSize.getHeight() - FOOTER_HEIGHT - CONTENT_BOTTOM_PADDING;
}

export function ensurePageSpace(doc: jsPDF, y: number, requiredHeight: number, nextPageStartY = CONTINUATION_START_Y): number {
  if (y + requiredHeight <= getContentBottomY(doc)) return y;
  doc.addPage();
  return nextPageStartY;
}

export function getPageWidth(doc: jsPDF): number {
  return doc.internal.pageSize.getWidth();
}

export function getPageHeight(doc: jsPDF): number {
  return doc.internal.pageSize.getHeight();
}

// ═══════════════════════════════════════════════════════════════
// LOGO LOADING
// ═══════════════════════════════════════════════════════════════
let _logoCache: string | null = null;

export function loadLogoBase64(): Promise<string> {
  if (_logoCache) return Promise.resolve(_logoCache);
  return new Promise((resolve) => {
    const img = new Image();
    img.crossOrigin = "anonymous";
    img.onload = () => {
      const canvas = document.createElement("canvas");
      canvas.width = img.width;
      canvas.height = img.height;
      const ctx = canvas.getContext("2d")!;
      ctx.drawImage(img, 0, 0);
      _logoCache = canvas.toDataURL("image/png");
      resolve(_logoCache);
    };
    img.onerror = () => resolve("");
    img.src = logoImg;
  });
}

// ═══════════════════════════════════════════════════════════════
// QR CODE
// ═══════════════════════════════════════════════════════════════
export async function generateCompanyQr(url?: string): Promise<string> {
  const cfg = await getPdfCompanyConfig();
  try {
    return await QRCode.toDataURL(url || cfg.website, {
      width: 200, margin: 1,
      color: { dark: "#282E38", light: "#FFFFFF" },
      errorCorrectionLevel: "M",
    });
  } catch { return ""; }
}

// ═══════════════════════════════════════════════════════════════
// DOCUMENT INIT
// ═══════════════════════════════════════════════════════════════
export interface PdfInitResult {
  doc: jsPDF;
  logoBase64: string;
  sig: SignatureData;
  qrDataUrl: string;
  cfg: PdfCompanyConfig;
}

export async function initPdf(options?: { orientation?: "portrait" | "landscape"; qrUrl?: string }): Promise<PdfInitResult> {
  const doc = new jsPDF({ orientation: options?.orientation || "portrait" });
  await registerBengaliFont(doc);
  const [logoBase64, sig, qrDataUrl, cfg] = await Promise.all([
    loadLogoBase64(),
    getSignatureData(),
    generateCompanyQr(options?.qrUrl),
    getPdfCompanyConfig(),
  ]);
  return { doc, logoBase64, sig, qrDataUrl, cfg };
}

// ═══════════════════════════════════════════════════════════════
// HEADER — Premium Left-aligned Logo Design
// ═══════════════════════════════════════════════════════════════
export async function addPdfHeader(
  doc: jsPDF, cfg: PdfCompanyConfig, logoBase64: string, qrDataUrl?: string
): Promise<number> {
  const pw = getPageWidth(doc);
  const phone2 = (cfg as any).phone2 || "+880 1711-999920";
  const logoBoxX = 14;
  const logoBoxY = 5;
  const logoMaxW = 28;
  const logoMaxH = 28;
  let logoRenderW = logoMaxW;
  let logoRenderH = logoMaxH;

  // ── Top accent bar — dark with orange accent ──
  doc.setFillColor(DARK.r, DARK.g, DARK.b);
  doc.rect(0, 0, pw, 2.5, "F");
  doc.setFillColor(ORANGE.r, ORANGE.g, ORANGE.b);
  doc.rect(0, 2.5, pw, 1, "F");

  // ── Logo — left side, large ──
  if (logoBase64) {
    try {
      const imageProps = doc.getImageProperties(logoBase64);
      const aspectRatio = imageProps.width / Math.max(imageProps.height, 1);
      logoRenderW = Math.min(logoMaxW, logoMaxH * aspectRatio);
      logoRenderH = logoRenderW / Math.max(aspectRatio, 0.01);

      if (logoRenderH > logoMaxH) {
        logoRenderH = logoMaxH;
        logoRenderW = logoRenderH * aspectRatio;
      }

      doc.addImage(
        logoBase64,
        "PNG",
        logoBoxX,
        logoBoxY + (logoMaxH - logoRenderH) / 2,
        logoRenderW,
        logoRenderH,
      );
    } catch { /* skip */ }
  }

  // ── Company details — right of logo, vertically centered ──
  const textX = logoBoxX + logoMaxW + 6;
  const contactMaxWidth = pw - textX - (qrDataUrl ? 30 : 16);
  const phoneLine = [cfg.phone, phone2].filter(Boolean).join(" | ");
  const emailLine = cfg.email ? `Email: ${cfg.email}` : "";

  if (typeof (doc as any).setCharSpace === "function") {
    (doc as any).setCharSpace(0);
  }

  const textCenterY = logoBoxY + logoMaxH / 2;

  // Company name
  doc.setFontSize(15);
  doc.setFont("helvetica", "bold");
  doc.setTextColor(DARK.r, DARK.g, DARK.b);
  doc.text(cfg.company_name, textX, textCenterY - 8);

  // Tagline
  doc.setFontSize(7.5);
  doc.setFont("helvetica", "normal");
  doc.setTextColor(ORANGE.r, ORANGE.g, ORANGE.b);
  doc.text(cfg.tagline || "Hajj & Umrah Services", textX, textCenterY - 3, { maxWidth: contactMaxWidth });

  // Phone
  doc.setFontSize(7);
  doc.setFont("helvetica", "normal");
  doc.setTextColor(MUTED.r, MUTED.g, MUTED.b);
  doc.text(`Phone: ${phoneLine}`, textX, textCenterY + 2, { maxWidth: contactMaxWidth });

  // Email
  if (emailLine) {
    doc.text(emailLine, textX, textCenterY + 6, { maxWidth: contactMaxWidth });
  }

  // Address
  if (cfg.address) {
    doc.setFontSize(6);
    doc.setTextColor(MUTED.r, MUTED.g, MUTED.b);
    if (hasBengali(cfg.address)) {
      await addBengaliText(doc, cfg.address, textX, textCenterY + 10, { fontSize: 5.5, color: "#787878", maxWidth: contactMaxWidth });
    } else {
      const addr = cfg.address.length > 100 ? cfg.address.substring(0, 100) + "..." : cfg.address;
      doc.text(addr, textX, textCenterY + 10, { maxWidth: contactMaxWidth });
    }
  }

  // QR code — top right corner
  if (qrDataUrl) {
    try {
      doc.addImage(qrDataUrl, "PNG", pw - 22, logoBoxY + 2, 14, 14);
      doc.setFontSize(4);
      doc.setTextColor(MUTED.r, MUTED.g, MUTED.b);
      doc.text("Scan to verify", pw - 15, logoBoxY + 18, { align: "center" });
    } catch { /* skip */ }
  }

  // ── Bottom separator ──
  const lineY = logoBoxY + logoMaxH + 3;
  doc.setDrawColor(DARK.r, DARK.g, DARK.b);
  doc.setLineWidth(0.6);
  doc.line(14, lineY, pw - 14, lineY);
  doc.setDrawColor(ORANGE.r, ORANGE.g, ORANGE.b);
  doc.setLineWidth(0.3);
  doc.line(14, lineY + 1, pw - 14, lineY + 1);
  doc.setLineWidth(0.2);

  doc.setTextColor(0);
  doc.setFontSize(10);

  return 39;
}

// ═══════════════════════════════════════════════════════════════
// FOOTER (with page numbers)
// ═══════════════════════════════════════════════════════════════
export function addPdfFooter(doc: jsPDF, cfg: PdfCompanyConfig, options?: { showPageNumbers?: boolean }) {
  const totalPages = doc.getNumberOfPages();

  for (let i = 1; i <= totalPages; i++) {
    doc.setPage(i);
    const pw = getPageWidth(doc);
    const ph = getPageHeight(doc);

    // Top line
    doc.setDrawColor(DARK.r, DARK.g, DARK.b);
    doc.setLineWidth(0.3);
    doc.line(14, ph - FOOTER_HEIGHT - 1, pw - 14, ph - FOOTER_HEIGHT - 1);

    // Footer text area
    doc.setFontSize(6);
    doc.setFont("helvetica", "normal");
    doc.setTextColor(MUTED.r, MUTED.g, MUTED.b);
    doc.text(cfg.footer_text, pw / 2, ph - 10, { align: "center" });

    doc.setFontSize(5);
    doc.text(cfg.footer_contact, pw / 2, ph - 6, { align: "center" });

    // Orange accent at bottom
    doc.setFillColor(ORANGE.r, ORANGE.g, ORANGE.b);
    doc.rect(0, ph - 2, pw, 2, "F");

    // Page numbers
    if (options?.showPageNumbers !== false && totalPages > 1) {
      doc.setFontSize(6);
      doc.setFont("helvetica", "normal");
      doc.setTextColor(MUTED.r, MUTED.g, MUTED.b);
      doc.text(`Page ${i} of ${totalPages}`, pw - 14, ph - 10, { align: "right" });
    }

    doc.setTextColor(0);
  }
}

// ═══════════════════════════════════════════════════════════════
// SIGNATURE BLOCK
// ═══════════════════════════════════════════════════════════════
export function addSignatureBlock(doc: jsPDF, sig: SignatureData, y: number): number {
  const pw = getPageWidth(doc);
  let lineY = ensurePageSpace(doc, y + 8, 16, 44);
  if (lineY < 44) lineY = 44;
  const rightCenter = pw - 47;

  // Stamp & signature images
  if (sig.stamp_base64) {
    try { doc.addImage(sig.stamp_base64, "PNG", rightCenter - 14, lineY - 30, 28, 28); } catch { /* skip */ }
  }
  if (sig.signature_base64) {
    try { doc.addImage(sig.signature_base64, "PNG", rightCenter - 12, lineY - 12, 24, 10); } catch { /* skip */ }
  }

  // Lines
  doc.setDrawColor(180);
  doc.line(14, lineY, 80, lineY);
  doc.line(pw - 80, lineY, pw - 14, lineY);

  doc.setFontSize(7);
  doc.setFont("helvetica", "normal");
  doc.setTextColor(100);
  doc.text("Customer Signature", 14, lineY + 5);

  if (sig.authorized_name) {
    doc.setFontSize(8);
    doc.setFont("helvetica", "bold");
    doc.setTextColor(DARK.r, DARK.g, DARK.b);
    doc.text(sig.authorized_name, rightCenter, lineY + 5, { align: "center" });
  } else {
    doc.text("Authorized Signature", pw - 80, lineY + 5);
  }

  if (sig.designation) {
    doc.setFontSize(6.5);
    doc.setFont("helvetica", "normal");
    doc.setTextColor(100);
    doc.text(sig.designation, rightCenter, lineY + 10, { align: "center" });
  }

  doc.setTextColor(0);
  return lineY + 14;
}

// ═══════════════════════════════════════════════════════════════
// DOCUMENT TITLE BLOCK
// ═══════════════════════════════════════════════════════════════
export type StatusType = "completed" | "pending" | "confirmed" | "cancelled" | "processing" | "paid" | "partial" | "due";

const STATUS_COLORS: Record<string, { r: number; g: number; b: number }> = {
  completed: { r: 34, g: 139, b: 34 },
  paid: { r: 34, g: 139, b: 34 },
  pending: { r: 210, g: 140, b: 20 },
  confirmed: { r: 30, g: 100, b: 200 },
  partial: { r: 210, g: 140, b: 20 },
  due: { r: 200, g: 40, b: 40 },
  cancelled: { r: 150, g: 50, b: 50 },
  processing: { r: 100, g: 100, b: 200 },
};

export function addTitleBlock(
  doc: jsPDF, y: number, title: string, status?: string | null
): number {
  const pw = getPageWidth(doc);

  // Title badge with orange left accent
  const titleW = Math.min(doc.getTextWidth(title) * 0.65 + 20, pw - 28);
  doc.setFillColor(DARK.r, DARK.g, DARK.b);
  doc.roundedRect(14, y, titleW, 10, 1.5, 1.5, "F");
  // Orange left accent
  doc.setFillColor(ORANGE.r, ORANGE.g, ORANGE.b);
  doc.rect(14, y, 3, 10, "F");

  doc.setFontSize(11);
  doc.setFont("helvetica", "bold");
  doc.setTextColor(255);
  doc.text(title.toUpperCase(), 20, y + 7);
  doc.setTextColor(0);

  // Status badge
  if (status) {
    const sc = STATUS_COLORS[status.toLowerCase()] || STATUS_COLORS.pending;
    const statusText = status.toUpperCase();
    const statusW = doc.getTextWidth(statusText) * 0.6 + 10;
    doc.setFillColor(sc.r, sc.g, sc.b);
    doc.roundedRect(pw - 14 - statusW, y, statusW, 10, 1.5, 1.5, "F");
    doc.setFontSize(8);
    doc.setFont("helvetica", "bold");
    doc.setTextColor(255);
    doc.text(statusText, pw - 14 - statusW / 2, y + 7, { align: "center" });
    doc.setTextColor(0);
  }

  return y + 16;
}

// ═══════════════════════════════════════════════════════════════
// METADATA LINE
// ═══════════════════════════════════════════════════════════════
export function addMetaLine(doc: jsPDF, y: number, leftItems: string[], rightItems: string[]): number {
  const pw = getPageWidth(doc);
  doc.setFontSize(8);
  doc.setFont("helvetica", "normal");
  doc.setTextColor(80);

  leftItems.filter(Boolean).forEach((t, i) => doc.text(t, 14, y + i * 5));
  rightItems.filter(Boolean).forEach((t, i) => doc.text(t, pw / 2 + 10, y + i * 5));

  doc.setTextColor(0);
  return y + Math.max(leftItems.filter(Boolean).length, rightItems.filter(Boolean).length) * 5 + 4;
}

// ═══════════════════════════════════════════════════════════════
// SECTION TITLE
// ═══════════════════════════════════════════════════════════════
export function addSectionTitle(doc: jsPDF, y: number, title: string): number {
  doc.setFontSize(9);
  doc.setFont("helvetica", "bold");
  doc.setTextColor(DARK.r, DARK.g, DARK.b);
  doc.text(title, 14, y);
  doc.setDrawColor(ORANGE.r, ORANGE.g, ORANGE.b);
  doc.setLineWidth(0.5);
  doc.line(14, y + 1.5, 14 + doc.getTextWidth(title), y + 1.5);
  doc.setLineWidth(0.2);
  doc.setTextColor(0);
  return y + 5;
}

// ═══════════════════════════════════════════════════════════════
// SUMMARY CARDS (Executive Summary)
// ═══════════════════════════════════════════════════════════════
export interface SummaryCard {
  label: string;
  value: string;
  highlight?: boolean;
}

export function addSummaryCards(doc: jsPDF, y: number, cards: SummaryCard[]): number {
  const pw = getPageWidth(doc);
  const margin = 14;
  const availW = pw - margin * 2;
  const cols = Math.min(cards.length, 4);
  const cardW = (availW - (cols - 1) * 3) / cols;
  const cardH = 16;

  y = ensurePageSpace(doc, y, cardH + 4);

  cards.forEach((card, i) => {
    const col = i % cols;
    const row = Math.floor(i / cols);
    const x = margin + col * (cardW + 3);
    const cy = y + row * (cardH + 3);

    if (card.highlight) {
      doc.setFillColor(DARK.r, DARK.g, DARK.b);
      doc.roundedRect(x, cy, cardW, cardH, 1.5, 1.5, "F");
      // Orange top accent
      doc.setFillColor(ORANGE.r, ORANGE.g, ORANGE.b);
      doc.rect(x, cy, cardW, 1.5, "F");
      doc.setTextColor(255);
    } else {
      doc.setFillColor(LIGHT_BG.r, LIGHT_BG.g, LIGHT_BG.b);
      doc.setDrawColor(220);
      doc.roundedRect(x, cy, cardW, cardH, 1.5, 1.5, "FD");
      doc.setTextColor(DARK.r, DARK.g, DARK.b);
    }

    doc.setFontSize(6.5);
    doc.setFont("helvetica", "normal");
    if (!card.highlight) doc.setTextColor(MUTED.r, MUTED.g, MUTED.b);
    doc.text(card.label.toUpperCase(), x + 4, cy + 5.5);

    doc.setFontSize(10);
    doc.setFont("helvetica", "bold");
    if (card.highlight) doc.setTextColor(255);
    else doc.setTextColor(DARK.r, DARK.g, DARK.b);
    doc.text(card.value, x + 4, cy + 12);
  });

  doc.setTextColor(0);
  const rows = Math.ceil(cards.length / cols);
  return y + rows * (cardH + 3) + 4;
}

// ═══════════════════════════════════════════════════════════════
// FILTER SUMMARY
// ═══════════════════════════════════════════════════════════════
export interface FilterItem {
  label: string;
  value: string;
}

export function addFilterSummary(doc: jsPDF, y: number, filters: FilterItem[]): number {
  const activeFilters = filters.filter(f => f.value && f.value !== "All" && f.value !== "all");
  if (activeFilters.length === 0) return y;

  const pw = getPageWidth(doc);
  y = ensurePageSpace(doc, y, 12);

  doc.setFillColor(245, 245, 245);
  doc.setDrawColor(220);

  const boxH = 6 + Math.ceil(activeFilters.length / 3) * 5;
  doc.roundedRect(14, y, pw - 28, boxH, 1, 1, "FD");

  doc.setFontSize(6.5);
  doc.setFont("helvetica", "bold");
  doc.setTextColor(MUTED.r, MUTED.g, MUTED.b);
  doc.text("APPLIED FILTERS:", 18, y + 4);

  doc.setFont("helvetica", "normal");
  doc.setFontSize(6.5);
  const colW = (pw - 36) / 3;
  activeFilters.forEach((f, i) => {
    const col = i % 3;
    const row = Math.floor(i / 3);
    doc.setTextColor(80);
    doc.text(`${f.label}: ${f.value}`, 18 + col * colW, y + 9 + row * 5);
  });

  doc.setTextColor(0);
  return y + boxH + 4;
}

// ═══════════════════════════════════════════════════════════════
// INFO BOX (for entity profiles)
// ═══════════════════════════════════════════════════════════════
export interface InfoField {
  label: string;
  value: string;
}

export async function addInfoBox(doc: jsPDF, y: number, fields: InfoField[], title?: string): Promise<number> {
  const pw = getPageWidth(doc);
  const rowH = 6;
  const rows = Math.ceil(fields.length / 2);
  const boxH = (title ? 10 : 4) + rows * rowH + 4;

  y = ensurePageSpace(doc, y, boxH);

  doc.setFillColor(LIGHT_BG.r, LIGHT_BG.g, LIGHT_BG.b);
  doc.setDrawColor(220);
  doc.rect(14, y, pw - 28, boxH, "FD");

  const col1 = 18;
  const col2 = pw / 2 + 5;
  let row = y + 4;

  if (title) {
    doc.setFontSize(9);
    doc.setFont("helvetica", "bold");
    doc.setTextColor(DARK.r, DARK.g, DARK.b);
    doc.text(title, col1, row + 4);

    doc.setDrawColor(ORANGE.r, ORANGE.g, ORANGE.b);
    doc.setLineWidth(0.5);
    doc.line(col1, row + 5.5, col1 + doc.getTextWidth(title), row + 5.5);
    doc.setLineWidth(0.2);
    row += 10;
  }

  doc.setFontSize(8);
  doc.setTextColor(50);

  for (let i = 0; i < fields.length; i++) {
    const f = fields[i];
    const col = i % 2 === 0 ? col1 : col2;
    if (i > 0 && i % 2 === 0) row += rowH;

    doc.setFont("helvetica", "bold");
    doc.text(`${f.label}:`, col, row);
    doc.setFont("helvetica", "normal");

    const labelW = doc.getTextWidth(`${f.label}:`) + 3;
    const val = f.value || "N/A";
    const truncatedVal = val.length > 35 ? val.substring(0, 35) + "..." : val;

    if (hasBengali(val)) {
      // Calculate available width to prevent overflow
      const availableWidth = (i % 2 === 0 ? col2 - col - labelW - 4 : pw - 14 - col - labelW - 4);
      const displayVal = val.length > 30 ? val.substring(0, 30) + "..." : val;
      await addBengaliText(doc, displayVal, col + labelW, row, { fontSize: 8, maxWidth: availableWidth });
    } else {
      doc.text(truncatedVal, col + labelW, row);
    }
  }

  doc.setTextColor(0);
  return y + boxH + 4;
}

// ═══════════════════════════════════════════════════════════════
// FINANCIAL SUMMARY BOX
// ═══════════════════════════════════════════════════════════════
export function addFinancialBox(
  doc: jsPDF, y: number,
  items: { label: string; value: string; bold?: boolean }[],
  options?: { width?: number; align?: "left" | "right" }
): number {
  const pw = getPageWidth(doc);
  const boxW = options?.width || 80;
  const boxX = options?.align === "left" ? 14 : pw - 14 - boxW;

  y = ensurePageSpace(doc, y, items.length * 7 + 8);

  doc.setDrawColor(220);
  doc.setFillColor(LIGHT_BG.r, LIGHT_BG.g, LIGHT_BG.b);
  doc.rect(boxX, y, boxW, items.length * 7 + 4, "FD");

  let iy = y + 5;
  doc.setFontSize(8);

  items.forEach((item, idx) => {
    doc.setFont("helvetica", item.bold ? "bold" : "normal");
    doc.setTextColor(item.bold ? DARK.r : 80, item.bold ? DARK.g : 80, item.bold ? DARK.b : 80);
    doc.text(item.label, boxX + 4, iy);
    doc.text(item.value, boxX + boxW - 4, iy, { align: "right" });

    if (idx === 2 && items.length > 3) {
      doc.setDrawColor(ORANGE.r, ORANGE.g, ORANGE.b);
      doc.setLineWidth(0.3);
      doc.line(boxX + 4, iy + 2, boxX + boxW - 4, iy + 2);
      doc.setLineWidth(0.2);
      iy += 3;
    }

    iy += 7;
  });

  doc.setTextColor(0);
  return y + items.length * 7 + 8;
}

// ═══════════════════════════════════════════════════════════════
// TOTALS BAR (dark bar with key-value pairs)
// ═══════════════════════════════════════════════════════════════
export function addTotalsBar(doc: jsPDF, y: number, items: string[], height = 12): number {
  const pw = getPageWidth(doc);
  y = ensurePageSpace(doc, y, height + 4);

  doc.setFillColor(DARK.r, DARK.g, DARK.b);
  doc.rect(14, y, pw - 28, height, "F");
  // Orange left accent
  doc.setFillColor(ORANGE.r, ORANGE.g, ORANGE.b);
  doc.rect(14, y, 3, height, "F");

  doc.setTextColor(255);
  doc.setFontSize(9);
  doc.setFont("helvetica", "bold");

  if (items.length === 1) {
    doc.text(items[0], 22, y + height / 2 + 2);
  } else {
    const spacing = (pw - 40) / items.length;
    items.forEach((item, i) => {
      doc.text(item, 22 + i * spacing, y + height / 2 + 2);
    });
  }

  doc.setTextColor(0);
  return y + height + 6;
}

// ═══════════════════════════════════════════════════════════════
// WATERMARK
// ═══════════════════════════════════════════════════════════════
export type WatermarkStatus = "paid" | "partial" | "due";

export function getWatermarkStatus(paidAmount: number, dueAmount: number): WatermarkStatus {
  if (dueAmount <= 0) return "paid";
  if (paidAmount > 0 && dueAmount > 0) return "partial";
  return "due";
}

export function addWatermark(doc: jsPDF, status: WatermarkStatus) {
  const pw = getPageWidth(doc);
  const ph = getPageHeight(doc);

  const config: Record<WatermarkStatus, { text: string; r: number; g: number; b: number }> = {
    paid: { text: "PAID", r: 34, g: 139, b: 34 },
    partial: { text: "PARTIAL", r: 210, g: 140, b: 20 },
    due: { text: "DUE", r: 200, g: 40, b: 40 },
  };

  const { text, r, g, b } = config[status];

  doc.saveGraphicsState();
  const gState = new (doc as any).GState({ opacity: 0.08 });
  doc.setGState(gState);
  doc.setTextColor(r, g, b);
  doc.setFontSize(72);
  doc.setFont("helvetica", "bold");
  doc.text(text, pw / 2, ph / 2, { align: "center", angle: 35 });
  doc.restoreGraphicsState();
  doc.setTextColor(0);
}

// ═══════════════════════════════════════════════════════════════
// STANDARD TABLE with autoTable
// ═══════════════════════════════════════════════════════════════
export interface PdfTableOptions {
  startY: number;
  head: string[];
  body: (string | number)[][];
  foot?: (string | number)[][];
  columnStyles?: Record<number, any>;
  showHead?: "everyPage" | "firstPage" | "never";
  fontSize?: number;
  margin?: { left?: number; right?: number };
  didParseCell?: (data: any) => void;
}

const getTableCellText = (data: any): string => {
  if (Array.isArray(data?.cell?.text) && data.cell.text.length > 0) {
    return data.cell.text.join(" ");
  }

  if (Array.isArray(data?.cell?.raw)) {
    return data.cell.raw.join(" ");
  }

  return String(data?.cell?.raw ?? "");
};

const buildDidParseCell = (callback?: (data: any) => void) => (data: any) => {
  const cellText = getTableCellText(data);
  data.cell.styles.font = hasBengali(cellText) ? "NotoSansBengali" : "helvetica";

  if (data.section === "head") {
    data.cell.styles.font = "helvetica";
    data.cell.styles.fontStyle = "bold";
  }

  if (data.section === "foot") {
    data.cell.styles.fontStyle = "bold";
  }

  callback?.(data);
};

export function addTable(doc: jsPDF, options: PdfTableOptions): number {
  autoTable(doc, {
    startY: options.startY,
    head: [options.head],
    body: options.body.map(row => row.map(cell =>
      typeof cell === "number" ? fmtBDT(cell) : cell
    )),
    foot: options.foot ? options.foot.map(row => row.map(cell =>
      typeof cell === "number" ? fmtBDT(cell) : cell
    )) : undefined,
    showHead: options.showHead || "everyPage",
    styles: {
      fontSize: options.fontSize || 7.5,
      cellPadding: 2.5,
      font: "helvetica",
    },
    headStyles: {
      fillColor: [DARK.r, DARK.g, DARK.b],
      textColor: [255, 255, 255],
      fontSize: options.fontSize || 7.5,
      font: "helvetica",
      fontStyle: "bold",
    },
    footStyles: {
      fillColor: [LIGHT_BG.r, LIGHT_BG.g, LIGHT_BG.b],
      textColor: [DARK.r, DARK.g, DARK.b],
      font: "helvetica",
      fontStyle: "bold",
      fontSize: 8,
    },
    alternateRowStyles: { fillColor: [LIGHT_BG.r, LIGHT_BG.g, LIGHT_BG.b] },
    columnStyles: options.columnStyles || {},
    margin: { left: options.margin?.left || 14, right: options.margin?.right || 14 },
    didParseCell: buildDidParseCell(options.didParseCell),
    didDrawCell: bengaliCellHook,
  });

  return ((doc as any).lastAutoTable?.finalY || options.startY + 20) + 6;
}

// ═══════════════════════════════════════════════════════════════
// RAW TABLE (no BDT formatting, raw strings passed as-is)
// ═══════════════════════════════════════════════════════════════
export function addRawTable(doc: jsPDF, options: PdfTableOptions): number {
  autoTable(doc, {
    startY: options.startY,
    head: [options.head],
    body: options.body,
    foot: options.foot,
    showHead: options.showHead || "everyPage",
    styles: {
      fontSize: options.fontSize || 7.5,
      cellPadding: 2.5,
      font: "helvetica",
    },
    headStyles: {
      fillColor: [DARK.r, DARK.g, DARK.b],
      textColor: [255, 255, 255],
      fontSize: options.fontSize || 7.5,
      font: "helvetica",
      fontStyle: "bold",
    },
    footStyles: {
      fillColor: [LIGHT_BG.r, LIGHT_BG.g, LIGHT_BG.b],
      textColor: [DARK.r, DARK.g, DARK.b],
      font: "helvetica",
      fontStyle: "bold",
      fontSize: 8,
    },
    alternateRowStyles: { fillColor: [LIGHT_BG.r, LIGHT_BG.g, LIGHT_BG.b] },
    columnStyles: options.columnStyles || {},
    margin: { left: options.margin?.left || 14, right: options.margin?.right || 14 },
    didParseCell: buildDidParseCell(options.didParseCell),
    didDrawCell: bengaliCellHook,
  });

  return ((doc as any).lastAutoTable?.finalY || options.startY + 20) + 6;
}

// ═══════════════════════════════════════════════════════════════
// DUE HIGHLIGHT BAR
// ═══════════════════════════════════════════════════════════════
export function addDueHighlight(doc: jsPDF, y: number, dueAmount: number): number {
  if (dueAmount <= 0) return y;

  const pw = getPageWidth(doc);
  const boxW = 80;
  const boxX = pw - 14 - boxW;

  doc.setFillColor(255, 240, 230);
  doc.setDrawColor(220, 120, 20);
  doc.roundedRect(boxX, y, boxW, 8, 1, 1, "FD");
  doc.setFontSize(7);
  doc.setFont("helvetica", "bold");
  doc.setTextColor(180, 80, 0);
  doc.text(`Outstanding Balance: ${fmtBDT(dueAmount)}`, boxX + boxW / 2, y + 5, { align: "center" });
  doc.setTextColor(0);

  return y + 12;
}

// ═══════════════════════════════════════════════════════════════
// BALANCE BAR (dark summary bar at bottom of receipts)
// ═══════════════════════════════════════════════════════════════
export function addBalanceBar(doc: jsPDF, y: number, leftLabel: string, leftValue: string, rightLabel: string, rightValue: string): number {
  const pw = getPageWidth(doc);
  y = ensurePageSpace(doc, y, 18);

  doc.setFillColor(DARK.r, DARK.g, DARK.b);
  doc.roundedRect(14, y, pw - 28, 14, 2, 2, "F");
  // Orange left accent
  doc.setFillColor(ORANGE.r, ORANGE.g, ORANGE.b);
  doc.rect(14, y, 3, 14, "F");
  doc.setTextColor(255);
  doc.setFontSize(9);
  doc.setFont("helvetica", "bold");
  doc.text(`${leftLabel}: ${leftValue}`, 22, y + 9);
  doc.text(`${rightLabel}: ${rightValue}`, pw - 20, y + 9, { align: "right" });
  doc.setTextColor(0);

  return y + 22;
}

// ═══════════════════════════════════════════════════════════════
// SAFE FILENAME
// ═══════════════════════════════════════════════════════════════
export function buildFileName(prefix: string, id?: string, ext = "pdf"): string {
  const date = new Date().toISOString().slice(0, 10);
  const safe = (id || "").replace(/\s+/g, "_").replace(/[^a-zA-Z0-9_-]/g, "");
  return `${prefix}${safe ? `_${safe}` : ""}_${date}.${ext}`;
}

// Re-exports for convenience
export { registerBengaliFont, addBengaliText, hasBengali, bengaliCellHook };
export { formatBDT, formatAmount };
export type { SignatureData, PdfCompanyConfig };
