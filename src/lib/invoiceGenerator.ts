import jsPDF from "jspdf";
import autoTable from "jspdf-autotable";
import {
  initPdf, addPdfHeader, addPdfFooter, addTitleBlock, addMetaLine,
  addSectionTitle, addInfoBox, addSignatureBlock, addWatermark,
  addRawTable, addDueHighlight, addBalanceBar,
  getWatermarkStatus, ensurePageSpace, buildFileName,
  fmtDate, fmtBDT, fmtAmount, bengaliCellHook,
  GOLD, DARK, LIGHT_BG, ORANGE,
  loadLogoBase64,
  type SummaryCard, type InfoField, type PdfCompanyConfig, type SignatureData,
} from "./pdfCore";
import { generateTrackingQr, addQrToDoc, addPaymentWatermark } from "./pdfQrCode";
import { supabase } from "@/lib/api";
import { registerBengaliFont, addBengaliText, hasBengali } from "./pdfFontLoader";
import { getSignatureData } from "./pdfSignature";
import { getPdfCompanyConfig } from "./pdfCompanyConfig";
import { formatBDT, formatAmount } from "@/lib/utils";

export interface CompanyInfo {
  name?: string;
  phone?: string;
  email?: string;
  address?: string;
}

export interface InvoiceCustomer {
  full_name?: string | null;
  phone?: string | null;
  email?: string | null;
  passport_number?: string | null;
  address?: string | null;
}

export interface InvoiceBooking {
  id?: string;
  tracking_id: string;
  total_amount: number;
  paid_amount: number;
  due_amount: number | null;
  discount?: number;
  num_travelers: number;
  created_at: string;
  status: string;
  booking_type?: string;
  moallem_id?: string | null;
  package_id?: string | null;
  guest_name?: string | null;
  guest_passport?: string | null;
  packages?: { name: string; type?: string; duration_days?: number | null; start_date?: string | null; price?: number | null } | null;
  selling_price_per_person?: number | null;
  notes?: string | null;
}

export interface InvoicePayment {
  id: string;
  amount: number;
  installment_number: number | null;
  status: string;
  due_date: string | null;
  paid_at: string | null;
  payment_method: string | null;
  booking_id: string;
}

export interface BookingMember {
  full_name: string;
  passport_number?: string | null;
  selling_price: number;
  discount: number;
  final_price: number;
  packages?: { name: string } | null;
  package_id?: string | null;
}

// ── Helpers ──
const fmtDateLocal = (d: string | null) =>
  d ? new Date(d).toLocaleDateString("en-GB", { day: "2-digit", month: "short", year: "numeric" }) : "—";

const FOOTER_HEIGHT = 14;
const CONTENT_BOTTOM_PADDING = 4;
const CONTINUATION_START_Y = 18;

function getContentBottomY(doc: jsPDF): number {
  return doc.internal.pageSize.getHeight() - FOOTER_HEIGHT - CONTENT_BOTTOM_PADDING;
}

function ensurePageSpaceLocal(doc: jsPDF, y: number, requiredHeight: number, nextPageStartY = CONTINUATION_START_Y): number {
  if (y + requiredHeight <= getContentBottomY(doc)) return y;
  doc.addPage();
  return nextPageStartY;
}

// ── Fetch booking members ──
async function fetchBookingMembers(bookingId: string, fallbackPackageName = "N/A"): Promise<BookingMember[]> {
  const { data, error } = await supabase
    .from("booking_members")
    .select("full_name, passport_number, selling_price, discount, final_price, package_id, packages(name)")
    .eq("booking_id", bookingId)
    .order("created_at", { ascending: true });

  if (error) {
    console.error("fetchBookingMembers error:", error);
    return [];
  }

  return normalizeMembers((data || []) as Partial<BookingMember>[], fallbackPackageName);
}

// ── Fetch moallem name ──
async function fetchMoallemName(moallemId: string): Promise<string> {
  const { data } = await supabase.from("moallems").select("name").eq("id", moallemId).maybeSingle();
  return data?.name || "N/A";
}

const normalizeBookingType = (value?: string | null) => (value || "").trim().toLowerCase();

const cleanText = (...values: unknown[]): string => {
  for (const value of values) {
    if (typeof value === "string") {
      const trimmed = value.trim();
      if (trimmed) return trimmed;
      continue;
    }
    if (typeof value === "number" && Number.isFinite(value)) {
      return String(value);
    }
  }
  return "";
};

const toPublicTrackingId = (value?: string | null): string => {
  const normalized = cleanText(value).toUpperCase();
  if (!normalized) return "";
  if (normalized.startsWith("MTH-")) return normalized;
  if (normalized.startsWith("RK-")) return `MTH-${normalized.slice(3)}`;
  return normalized;
};

const resolvePackageName = (value: unknown): string => {
  if (Array.isArray(value)) {
    return cleanText(value[0]?.name, value[0]?.title, value[0]?.package_name, value[0]?.packageName);
  }

  if (value && typeof value === "object") {
    const pkg = value as Record<string, unknown>;
    return cleanText(pkg.name, pkg.title, pkg.package_name, pkg.packageName);
  }

  return cleanText(value);
};

const resolveBookingPackageName = (booking: Partial<InvoiceBooking> & Record<string, unknown>, fallback = ""): string => {
  return cleanText(
    resolvePackageName(booking.packages),
    booking.package_name,
    booking.packageName,
    fallback,
  );
};

const extractDelimitedValues = (value?: string | null): string[] => {
  const source = cleanText(value);
  if (!source) return [];
  return source.split(/[\n,;|/]+/).map((item) => item.trim()).filter(Boolean);
};

const isGenericTravelerLabel = (value?: string | null): boolean => {
  const normalized = cleanText(value);
  if (!normalized) return false;
  return /^travell?er\s*#?\d+$/i.test(normalized);
};

async function fetchPackageNameMap(packageIds: string[]): Promise<Record<string, string>> {
  const uniqueIds = Array.from(new Set(packageIds.filter(Boolean)));
  if (uniqueIds.length === 0) return {};
  const { data, error } = await supabase.from("packages").select("id, name").in("id", uniqueIds);
  if (error) return {};
  return (data || []).reduce((acc: Record<string, string>, row: any) => {
    const id = cleanText(row?.id);
    const name = cleanText(row?.name);
    if (id && name) acc[id] = name;
    return acc;
  }, {} as Record<string, string>);
}

async function fetchBookingGuestFallback(trackingId: string): Promise<{ guest_name: string | null; guest_passport: string | null } | null> {
  const normalizedTrackingId = cleanText(trackingId).toUpperCase();
  if (!normalizedTrackingId) return null;
  const { data, error } = await supabase
    .from("bookings").select("guest_name, guest_passport")
    .eq("tracking_id", normalizedTrackingId).maybeSingle();
  if (error) return null;
  return { guest_name: (data as any)?.guest_name || null, guest_passport: (data as any)?.guest_passport || null };
}

const hasMeaningfulName = (value?: string | null) => {
  const normalized = cleanText(value);
  return Boolean(normalized && !isGenericTravelerLabel(normalized));
};

function normalizeMembers(members: Partial<BookingMember>[], fallbackPackageName: string): BookingMember[] {
  return (members || []).map((member) => {
    const memberAny = member as any;
    const rawPackage = memberAny?.packages;
    const packageName = cleanText(
      Array.isArray(rawPackage) ? rawPackage[0]?.name : rawPackage?.name,
      memberAny?.package_name, memberAny?.packageName, fallbackPackageName, "N/A"
    );
    const selling = Math.max(0, Number(memberAny?.selling_price ?? memberAny?.price ?? 0));
    const discount = Math.min(Math.max(0, Number(memberAny?.discount ?? 0)), selling);
    const fallbackFinal = Math.max(0, selling - discount);
    const finalPrice = Math.max(0, Number(memberAny?.final_price ?? memberAny?.finalPrice ?? fallbackFinal));
    return {
      full_name: cleanText(memberAny?.full_name, memberAny?.fullName, memberAny?.name, memberAny?.traveler_name, memberAny?.travelerName, memberAny?.member_name, memberAny?.memberName),
      passport_number: cleanText(memberAny?.passport_number, memberAny?.passportNumber, memberAny?.passport, memberAny?.traveler_passport, memberAny?.travelerPassport, memberAny?.member_passport, memberAny?.memberPassport) || null,
      package_id: cleanText(memberAny?.package_id, memberAny?.packageId) || null,
      packages: { name: packageName },
      selling_price: selling,
      discount,
      final_price: finalPrice,
    };
  });
}

function buildFallbackMembers(booking: InvoiceBooking, customer: InvoiceCustomer): BookingMember[] {
  const travelerCount = Math.max(Number(booking.num_travelers || 0), 0);
  if (travelerCount <= 1) return [];
  const packageName = resolveBookingPackageName(booking as Partial<InvoiceBooking> & Record<string, unknown>, "N/A");
  const unitPriceHint = Math.max(0, Number(booking.selling_price_per_person || 0), Number(booking.packages?.price || 0));
  const roundedTotal = Math.max(0, Math.round(Number(booking.total_amount || 0)));
  const roundedDiscount = Math.max(0, Math.round(Number(booking.discount || 0)));
  const roundedGross = roundedTotal + roundedDiscount;
  const distribute = (total: number, count: number, index: number) => {
    const base = Math.floor(total / count);
    const remainder = total % count;
    return base + (index < remainder ? 1 : 0);
  };
  return Array.from({ length: travelerCount }, (_, index) => {
    const gross = unitPriceHint > 0 ? Math.round(unitPriceHint) : distribute(roundedGross, travelerCount, index);
    const discount = distribute(roundedDiscount, travelerCount, index);
    const final = Math.max(0, gross - discount);
    return { full_name: "", passport_number: null, selling_price: gross, discount, final_price: final, packages: { name: packageName }, package_id: booking.package_id || null };
  });
}

// ═══════════════════════════════════════════════════════════════
// CUSTOMER SECTION (used in invoices/receipts)
// ═══════════════════════════════════════════════════════════════

async function addCustomerSection(
  doc: jsPDF, y: number, customer: InvoiceCustomer, moallemName?: string | null, totalMembers?: number, notes?: string | null
): Promise<number> {
  const fields: InfoField[] = [
    { label: "Name", value: customer.full_name || "N/A" },
    { label: "Phone", value: customer.phone || "N/A" },
    { label: "Passport", value: customer.passport_number || "N/A" },
    { label: "Address", value: customer.address || "N/A" },
  ];
  if (customer.email) fields.push({ label: "Email", value: customer.email });
  if (moallemName) fields.push({ label: "Moallem", value: moallemName });
  if (totalMembers) fields.push({ label: "Members", value: String(totalMembers) });
  if (notes) fields.push({ label: "Notes", value: notes.length > 60 ? notes.substring(0, 60) + "..." : notes });

  return addInfoBox(doc, y, fields, "BILL TO");
}

function addInvoiceTitleBlock(
  doc: jsPDF, y: number, trackingId: string, invoiceDate: string,
  travelDate: string | null, paymentStatus: string, isFamily: boolean
): number {
  const publicTrackingId = toPublicTrackingId(trackingId);
  y = addTitleBlock(doc, y, isFamily ? "FAMILY INVOICE" : "INVOICE", paymentStatus);
  y = addMetaLine(doc, y,
    [`Invoice No: ${publicTrackingId}`, `Invoice Date: ${fmtDateLocal(invoiceDate)}`],
    [`Booking ID: ${publicTrackingId}`, travelDate ? `Travel Date: ${fmtDateLocal(travelDate)}` : ""].filter(Boolean)
  );
  return y;
}

function addFinancialSummary(
  doc: jsPDF, y: number,
  grossAmount: number, discount: number, netTotal: number,
  paidAmount: number, dueAmount: number
): number {
  const pageWidth = doc.internal.pageSize.getWidth();
  const boxX = pageWidth - 14 - 80;
  const boxW = 80;

  doc.setDrawColor(220);
  doc.setFillColor(LIGHT_BG.r, LIGHT_BG.g, LIGHT_BG.b);
  doc.rect(boxX, y, boxW, 38, "FD");

  doc.setFontSize(8);
  const items = [
    { label: "Gross Amount:", value: formatBDT(grossAmount), bold: false },
    { label: "Discount:", value: `- ${formatBDT(discount)}`, bold: false },
    { label: "Net Total:", value: formatBDT(netTotal), bold: true },
    { label: "Paid Amount:", value: formatBDT(paidAmount), bold: false },
    { label: "Due Amount:", value: formatBDT(dueAmount), bold: true },
  ];

  let iy = y + 6;
  items.forEach((item, idx) => {
    doc.setFont("helvetica", item.bold ? "bold" : "normal");
    doc.setTextColor(item.bold ? DARK.r : 80, item.bold ? DARK.g : 80, item.bold ? DARK.b : 80);
    doc.text(item.label, boxX + 4, iy);
    doc.text(item.value, boxX + boxW - 4, iy, { align: "right" });
    if (idx === 2) {
      doc.setDrawColor(ORANGE.r, ORANGE.g, ORANGE.b);
      doc.setLineWidth(0.3);
      doc.line(boxX + 4, iy + 2, boxX + boxW - 4, iy + 2);
      doc.setLineWidth(0.2);
      iy += 3;
    }
    iy += 6;
  });

  if (dueAmount > 0) {
    doc.setFillColor(255, 240, 230);
    doc.setDrawColor(220, 120, 20);
    doc.roundedRect(boxX, y + 40, boxW, 8, 1, 1, "FD");
    doc.setFontSize(7);
    doc.setFont("helvetica", "bold");
    doc.setTextColor(180, 80, 0);
    doc.text(`Outstanding Balance: ${formatBDT(dueAmount)}`, boxX + boxW / 2, y + 45, { align: "center" });
  }

  doc.setTextColor(0);
  return y + (dueAmount > 0 ? 52 : 42);
}

function addPaymentHistoryTable(doc: jsPDF, y: number, payments: InvoicePayment[]): number {
  y = addSectionTitle(doc, y, "PAYMENT HISTORY");

  const completed = payments.filter(p => p.status === "completed").sort((a, b) => new Date(a.paid_at || 0).getTime() - new Date(b.paid_at || 0).getTime());
  const pending = payments.filter(p => p.status === "pending").sort((a, b) => new Date(a.due_date || 0).getTime() - new Date(b.due_date || 0).getTime());

  if (completed.length === 0 && pending.length === 0) {
    doc.setFontSize(8);
    doc.setFont("helvetica", "italic");
    doc.setTextColor(130);
    doc.text("No payments recorded yet.", 14, y + 4);
    doc.setTextColor(0);
    return y + 10;
  }

  const totalPaid = completed.reduce((s, p) => s + Number(p.amount), 0);

  const bodyRows = [
    ...completed.map((p, i) => [
      String(i + 1), fmtDateLocal(p.paid_at),
      (p.payment_method || "Manual").charAt(0).toUpperCase() + (p.payment_method || "manual").slice(1),
      formatAmount(Number(p.amount)), "Paid",
    ]),
    ...pending.map((p, i) => [
      String(completed.length + i + 1),
      p.due_date ? fmtDateLocal(p.due_date) + " (Due)" : "—",
      "—", formatAmount(Number(p.amount)), "Pending",
    ]),
  ];

  return addRawTable(doc, {
    startY: y,
    head: ["#", "Date", "Method", "Amount (BDT)", "Status"],
    body: bodyRows,
    foot: completed.length > 0 ? [["", "", "Total Paid", formatAmount(totalPaid), ""]] : undefined,
    columnStyles: {
      0: { cellWidth: 12, halign: "center" },
      3: { halign: "right", fontStyle: "bold" },
      4: { cellWidth: 18, halign: "center" },
    },
    didParseCell: (data: any) => {
      if (data.section === "body" && data.column.index === 4) {
        if (data.cell.raw === "Paid") {
          data.cell.styles.textColor = [34, 139, 34];
          data.cell.styles.fontStyle = "bold";
        } else if (data.cell.raw === "Pending") {
          data.cell.styles.textColor = [210, 140, 20];
          data.cell.styles.fontStyle = "bold";
        }
      }
    },
  });
}

// ═══════════════════════════════════════════════════════════════
// INDIVIDUAL INVOICE
// ═══════════════════════════════════════════════════════════════

async function generateIndividualInvoice(
  doc: jsPDF, booking: InvoiceBooking, customer: InvoiceCustomer,
  payments: InvoicePayment[], logoBase64: string, sig: SignatureData,
  qrDataUrl: string, moallemName: string | null, cfg: PdfCompanyConfig
) {
  let y = await addPdfHeader(doc, cfg, logoBase64, qrDataUrl);
  const packageName = resolveBookingPackageName(booking as Partial<InvoiceBooking> & Record<string, unknown>, "N/A");

  addPaymentWatermark(doc, getWatermarkStatus(Number(booking.paid_amount), Number(booking.due_amount || 0)));

  y = addInvoiceTitleBlock(doc, y, booking.tracking_id, new Date().toISOString(), booking.packages?.start_date || null, booking.status, false);
  y = await addCustomerSection(doc, y, customer, moallemName, undefined, booking.notes);

  y = addSectionTitle(doc, y, "SERVICE DETAILS");

  const rawSellingPrice = Number(booking.selling_price_per_person || 0);
  const rawPackagePrice = Number(booking.packages?.price || 0);
  const unitPrice = rawSellingPrice > 0 ? rawSellingPrice : (rawPackagePrice > 0 ? rawPackagePrice : Math.round(Number(booking.total_amount) / Math.max(booking.num_travelers, 1)));
  const discount = Number(booking.discount || 0);
  const grossAmount = unitPrice * booking.num_travelers;

  y = addRawTable(doc, {
    startY: y,
    head: ["Package", "Qty", "Unit Price (BDT)", "Discount (BDT)", "Total (BDT)"],
    body: [[
      packageName,
      String(booking.num_travelers),
      formatAmount(unitPrice),
      formatAmount(discount),
      formatAmount(Number(booking.total_amount)),
    ]],
    columnStyles: {
      0: { cellWidth: 72 },
      1: { halign: "center", cellWidth: 15 },
      2: { halign: "right" },
      3: { halign: "right" },
      4: { halign: "right", fontStyle: "bold" },
    },
    fontSize: 8,
  });

  const netTotal = Number(booking.total_amount);
  const dueAmount = Number(booking.due_amount || 0);
  y = ensurePageSpaceLocal(doc, y, dueAmount > 0 ? 54 : 44);
  y = addFinancialSummary(doc, y, grossAmount, discount, netTotal, Number(booking.paid_amount), dueAmount);

  y = ensurePageSpaceLocal(doc, y, 26);
  y = addPaymentHistoryTable(doc, y, payments);

  y = addSignatureBlock(doc, sig, y);
  addPdfFooter(doc, cfg);
}

// ═══════════════════════════════════════════════════════════════
// FAMILY INVOICE
// ═══════════════════════════════════════════════════════════════

async function generateFamilyInvoice(
  doc: jsPDF, booking: InvoiceBooking, customer: InvoiceCustomer,
  payments: InvoicePayment[], members: BookingMember[],
  logoBase64: string, sig: SignatureData, qrDataUrl: string, moallemName: string | null, cfg: PdfCompanyConfig
) {
  let y = await addPdfHeader(doc, cfg, logoBase64, qrDataUrl);
  const packageName = resolveBookingPackageName(booking as Partial<InvoiceBooking> & Record<string, unknown>, "N/A");

  addPaymentWatermark(doc, getWatermarkStatus(Number(booking.paid_amount), Number(booking.due_amount || 0)));

  y = addInvoiceTitleBlock(doc, y, booking.tracking_id, new Date().toISOString(), booking.packages?.start_date || null, booking.status, true);
  y = await addCustomerSection(doc, y, customer, moallemName, members.length || booking.num_travelers, booking.notes);

  y = addSectionTitle(doc, y, "FAMILY MEMBERS");

  const totalGross = members.reduce((s, m) => s + Number(m.selling_price), 0) || Number(booking.total_amount) + Number(booking.discount || 0);
  const totalDiscount = members.reduce((s, m) => s + Number(m.discount), 0) || Number(booking.discount || 0);
  const totalFinal = members.reduce((s, m) => s + Number(m.final_price), 0) || Number(booking.total_amount);

  y = addRawTable(doc, {
    startY: y,
    head: ["SL", "Name", "Passport", "Package", "Price (BDT)", "Discount (BDT)", "Final (BDT)"],
    body: members.map((m, i) => {
      const name = cleanText(m.full_name, i === 0 ? customer.full_name : "", "—");
      const passport = cleanText(m.passport_number, i === 0 ? customer.passport_number : "", "—");
      const pkg = cleanText(m.packages?.name, packageName, "N/A");
      return [String(i + 1), name, passport, pkg, formatAmount(Number(m.selling_price)), formatAmount(Number(m.discount)), formatAmount(Number(m.final_price))];
    }),
    foot: [["", "", "", "TOTAL", formatAmount(totalGross), formatAmount(totalDiscount), formatAmount(totalFinal)]],
    columnStyles: {
      0: { cellWidth: 12, halign: "center" },
      3: { cellWidth: 34 },
      4: { halign: "right" },
      5: { halign: "right" },
      6: { halign: "right", fontStyle: "bold" },
    },
  });

  const familyDueAmount = Number(booking.due_amount || 0);
  y = ensurePageSpaceLocal(doc, y, familyDueAmount > 0 ? 54 : 44);
  y = addFinancialSummary(doc, y, totalGross, totalDiscount, totalFinal, Number(booking.paid_amount), familyDueAmount);

  y = ensurePageSpaceLocal(doc, y, 26);
  y = addPaymentHistoryTable(doc, y, payments);

  y = addSignatureBlock(doc, sig, y);
  addPdfFooter(doc, cfg);
}

// ═══════════════════════════════════════════════════════════════
// PUBLIC API
// ═══════════════════════════════════════════════════════════════

export interface GenerateInvoiceOptions {
  members?: Partial<BookingMember>[];
  forceFamily?: boolean;
}

export async function generateInvoice(
  booking: InvoiceBooking, customer: InvoiceCustomer,
  payments: InvoicePayment[], company: CompanyInfo,
  options: GenerateInvoiceOptions = {}
) {
  const doc = new jsPDF({ unit: "mm", format: "a4" });
  await registerBengaliFont(doc);
  const [logoBase64, sig, qrDataUrl, cfg] = await Promise.all([
    loadLogoBase64(), getSignatureData(), generateTrackingQr(booking.tracking_id), getPdfCompanyConfig(),
  ]);

  let moallemName: string | null = null;
  if (booking.moallem_id) moallemName = await fetchMoallemName(booking.moallem_id);

  let fallbackPackageName = resolveBookingPackageName(booking as Partial<InvoiceBooking> & Record<string, unknown>);
  if (!fallbackPackageName && booking.package_id) {
    const packageMap = await fetchPackageNameMap([booking.package_id]);
    fallbackPackageName = cleanText(packageMap[booking.package_id]);
  }
  fallbackPackageName = cleanText(fallbackPackageName, "N/A");

  const normalizedPackageMeta = (Array.isArray((booking as any).packages)
    ? (booking as any).packages[0]
    : booking.packages) as Record<string, unknown> | null | undefined;

  const providedMembers = normalizeMembers(options.members || [], fallbackPackageName);
  const dbMembers = providedMembers.length === 0 && booking.id ? await fetchBookingMembers(booking.id, fallbackPackageName) : [];

  const travelerCount = Math.max(Number(booking.num_travelers || 0), providedMembers.length, dbMembers.length, 1);
  const normalizedBooking: InvoiceBooking = {
    ...booking,
    num_travelers: travelerCount,
    packages: normalizedPackageMeta
      ? { ...normalizedPackageMeta, name: resolveBookingPackageName(booking as Partial<InvoiceBooking> & Record<string, unknown>, fallbackPackageName) }
      : { name: fallbackPackageName },
  };

  const normalizedType = normalizeBookingType(normalizedBooking.booking_type);
  const hasFamilySignal = Boolean(options.forceFamily) || normalizedType.includes("family") || travelerCount > 1 || providedMembers.length > 0 || dbMembers.length > 0;

  const rawInvoiceMembersBase = providedMembers.length > 0 ? providedMembers : dbMembers.length > 0 ? dbMembers : (hasFamilySignal ? buildFallbackMembers(normalizedBooking, customer) : []);
  const fallbackMembers = hasFamilySignal ? buildFallbackMembers(normalizedBooking, customer) : [];
  const rawInvoiceMembers = rawInvoiceMembersBase.length >= travelerCount ? rawInvoiceMembersBase : [...rawInvoiceMembersBase, ...fallbackMembers.slice(rawInvoiceMembersBase.length, travelerCount)];

  const missingPackageIds = rawInvoiceMembers.filter((m) => !cleanText(m.packages?.name) && Boolean(m.package_id)).map((m) => m.package_id as string);
  const packageNameMap = await fetchPackageNameMap(missingPackageIds);

  const customerName = cleanText(customer.full_name, "Primary Traveler");
  const customerPassport = cleanText(customer.passport_number);
  let fallbackGuestNames = extractDelimitedValues(normalizedBooking.guest_name);
  let fallbackGuestPassports = extractDelimitedValues(normalizedBooking.guest_passport);

  const hasAnyMeaningfulMemberName = rawInvoiceMembers.some((member) => hasMeaningfulName(cleanText(member.full_name, (member as any)?.traveler_name, (member as any)?.travelerName, (member as any)?.member_name, (member as any)?.memberName)));

  if (hasFamilySignal && normalizedBooking.tracking_id && (!hasAnyMeaningfulMemberName || fallbackGuestNames.length < travelerCount)) {
    const latestGuestFallback = await fetchBookingGuestFallback(normalizedBooking.tracking_id);
    const latestGuestNames = extractDelimitedValues(latestGuestFallback?.guest_name);
    const latestGuestPassports = extractDelimitedValues(latestGuestFallback?.guest_passport);
    if (latestGuestNames.length > fallbackGuestNames.length) fallbackGuestNames = latestGuestNames;
    if (latestGuestPassports.length > fallbackGuestPassports.length) fallbackGuestPassports = latestGuestPassports;
  }

  const invoiceMembers = rawInvoiceMembers.map((member, index) => {
    const resolvedPackageName = cleanText(member.packages?.name, member.package_id ? packageNameMap[member.package_id] : "", fallbackPackageName, "N/A");
    const rawMemberName = cleanText(member.full_name, (member as any)?.traveler_name, (member as any)?.travelerName, (member as any)?.member_name, (member as any)?.memberName);
    const resolvedName = cleanText(hasMeaningfulName(rawMemberName) ? rawMemberName : "", fallbackGuestNames[index], index === 0 ? customerName : "", "—");
    const resolvedPassport = cleanText(member.passport_number, (member as any)?.traveler_passport, (member as any)?.travelerPassport, (member as any)?.member_passport, (member as any)?.memberPassport, fallbackGuestPassports[index], index === 0 ? customerPassport : "");
    return { ...member, full_name: resolvedName, passport_number: resolvedPassport || null, packages: { name: resolvedPackageName } };
  });

  if (hasFamilySignal && invoiceMembers.length > 0) {
    await generateFamilyInvoice(doc, normalizedBooking, customer, payments, invoiceMembers, logoBase64, sig, qrDataUrl, moallemName, cfg);
  } else {
    await generateIndividualInvoice(doc, normalizedBooking, customer, payments, logoBase64, sig, qrDataUrl, moallemName, cfg);
  }

  doc.save(`Invoice-${toPublicTrackingId(normalizedBooking.tracking_id)}.pdf`);
}

// ═══════════════════════════════════════════════════════════════
// RECEIPT
// ═══════════════════════════════════════════════════════════════

export async function generateReceipt(
  payment: InvoicePayment, booking: InvoiceBooking,
  customer: InvoiceCustomer, company: CompanyInfo,
  allPayments?: InvoicePayment[]
) {
  const doc = new jsPDF({ unit: "mm", format: "a4" });
  await registerBengaliFont(doc);
  const [logoBase64, sig, qrDataUrl, cfg] = await Promise.all([
    loadLogoBase64(), getSignatureData(), generateTrackingQr(booking.tracking_id), getPdfCompanyConfig(),
  ]);

  let y = await addPdfHeader(doc, cfg, logoBase64, qrDataUrl);
  addPaymentWatermark(doc, "paid");

  y = addTitleBlock(doc, y, "PAYMENT RECEIPT", "paid");

  const publicTrackingId = toPublicTrackingId(booking.tracking_id);
  const receiptNum = `${publicTrackingId}-${payment.installment_number || "P"}`;
  y = addMetaLine(doc, y,
    [`Receipt #: ${receiptNum}`, `Date: ${fmtDateLocal(payment.paid_at || new Date().toISOString())}`],
    [`Booking ID: ${publicTrackingId}`]
  );

  y = await addCustomerSection(doc, y, customer);

  y = addRawTable(doc, {
    startY: y,
    head: ["Description", "Details"],
    body: [
      ["Booking ID", publicTrackingId],
      ["Package", resolveBookingPackageName(booking as Partial<InvoiceBooking> & Record<string, unknown>, "N/A")],
      ["Installment #", String(payment.installment_number || "—")],
      ["Amount Paid", formatBDT(Number(payment.amount))],
      ["Payment Date", fmtDateLocal(payment.paid_at)],
      ["Payment Method", (payment.payment_method || "Manual").charAt(0).toUpperCase() + (payment.payment_method || "manual").slice(1)],
    ],
    columnStyles: { 0: { fontStyle: "bold", cellWidth: 50 } },
    fontSize: 8,
  });

  const paidPayments = (allPayments || []).filter(p => p.status === "completed");
  const totalPaidSoFar = paidPayments.reduce((s, p) => s + Number(p.amount), 0);
  const remaining = Math.max(0, Number(booking.total_amount) - totalPaidSoFar);

  y = addBalanceBar(doc, y, "Total Paid", formatBDT(totalPaidSoFar), "Remaining Due", formatBDT(remaining));
  y = addSignatureBlock(doc, sig, y);
  addPdfFooter(doc, cfg);

  doc.save(`Receipt-${receiptNum}.pdf`);
}

// ═══════════════════════════════════════════════════════════════
// COMMISSION RECEIPT
// ═══════════════════════════════════════════════════════════════

export interface CommissionReceiptData {
  moallemName: string;
  moallemPhone?: string | null;
  bookingTrackingId: string;
  packageName: string;
  numTravelers: number;
  commissionPerPerson: number;
  totalCommission: number;
  commissionPaid: number;
  commissionDue: number;
  paymentAmount: number;
  paymentDate: string;
  paymentMethod: string;
  notes?: string | null;
}

export async function generateCommissionReceipt(data: CommissionReceiptData, company: CompanyInfo) {
  const doc = new jsPDF({ unit: "mm", format: "a4" });
  await registerBengaliFont(doc);
  const [logoBase64, sig, qrDataUrl, cfg] = await Promise.all([
    loadLogoBase64(), getSignatureData(), generateTrackingQr(data.bookingTrackingId), getPdfCompanyConfig(),
  ]);

  let y = await addPdfHeader(doc, cfg, logoBase64, qrDataUrl);
  addPaymentWatermark(doc, getWatermarkStatus(data.commissionPaid, data.commissionDue));

  y = addTitleBlock(doc, y, "COMMISSION PAYMENT RECEIPT", null);
  y = addMetaLine(doc, y, [`Date: ${fmtDateLocal(data.paymentDate)}`], []);

  y = await addInfoBox(doc, y, [
    { label: "Moallem", value: data.moallemName },
    { label: "Phone", value: data.moallemPhone || "N/A" },
  ], "PAID TO (MOALLEM)");

  const publicTrackingId = toPublicTrackingId(data.bookingTrackingId);

  y = addRawTable(doc, {
    startY: y,
    head: ["Description", "Details"],
    body: [
      ["Booking ID", publicTrackingId],
      ["Package", data.packageName],
      ["Travelers", String(data.numTravelers)],
      ["Commission/Person", formatBDT(data.commissionPerPerson)],
      ["Total Commission", formatBDT(data.totalCommission)],
      ["Amount Paid Now", formatBDT(data.paymentAmount)],
      ["Payment Method", (data.paymentMethod || "Cash").charAt(0).toUpperCase() + (data.paymentMethod || "cash").slice(1)],
      ["Total Paid So Far", formatBDT(data.commissionPaid)],
      ["Commission Due", formatBDT(data.commissionDue)],
      ...(data.notes ? [["Notes", data.notes]] : []),
    ],
    columnStyles: { 0: { fontStyle: "bold", cellWidth: 55 } },
    fontSize: 8,
  });

  y = addBalanceBar(doc, y, "Paid", formatBDT(data.paymentAmount), "Remaining Due", formatBDT(Math.max(0, data.commissionDue)));
  y = addSignatureBlock(doc, sig, y);
  addPdfFooter(doc, cfg);

  doc.save(`Commission_Receipt_${toPublicTrackingId(data.bookingTrackingId)}.pdf`);
}
