/**
 * entityPdfGenerator.ts — Moallem, Supplier, Customer Profile PDFs
 * Uses unified pdfCore design system.
 */
import { CompanyInfo } from "./invoiceGenerator";
import {
  initPdf, addPdfHeader, addPdfFooter, addTitleBlock, addSummaryCards,
  addSectionTitle, addInfoBox, addTable, addRawTable, addSignatureBlock,
  addWatermark, getWatermarkStatus, addTotalsBar, buildFileName,
  fmtDate, fmtBDT, fmtAmount,
  DARK, ORANGE, LIGHT_BG,
  type SummaryCard, type InfoField,
} from "./pdfCore";
import { getPdfCompanyConfig } from "./pdfCompanyConfig";
import { formatBDT } from "@/lib/utils";

// ── Moallem Profile PDF ──
export interface MoallemPdfData {
  name: string;
  phone?: string | null;
  address?: string | null;
  nid_number?: string | null;
  contract_date?: string | null;
  status: string;
  notes?: string | null;
  bookings: { tracking_id: string; guest_name: string; package_name: string; total: number; paid: number; due: number; status: string; date: string }[];
  moallemPayments: { amount: number; date: string; method: string; notes?: string | null }[];
  commissionPayments: { amount: number; date: string; method: string; notes?: string | null }[];
  summary: { totalBookings: number; totalTravelers: number; totalAmount: number; totalPaid: number; totalDue: number; totalDeposit: number; totalCommission: number; commissionPaid: number; commissionDue: number };
}

export async function generateMoallemPdf(data: MoallemPdfData, _company: CompanyInfo) {
  const { doc, logoBase64, sig, qrDataUrl, cfg } = await initPdf();

  let y = await addPdfHeader(doc, cfg, logoBase64, qrDataUrl);

  // Watermark
  const wmStatus = getWatermarkStatus(data.summary.totalPaid, data.summary.totalDue);
  addWatermark(doc, wmStatus);

  // Title
  y = addTitleBlock(doc, y, "Moallem Profile Report", data.status);

  // Info box
  const fields: InfoField[] = [
    { label: "Name", value: data.name },
    { label: "Phone", value: data.phone || "N/A" },
    { label: "NID", value: data.nid_number || "N/A" },
    { label: "Contract Date", value: fmtDate(data.contract_date) },
    { label: "Address", value: data.address || "N/A" },
    { label: "Status", value: data.status },
  ];
  y = await addInfoBox(doc, y, fields, "Moallem Details");

  // Summary cards
  const cards: SummaryCard[] = [
    { label: "Total Bookings", value: String(data.summary.totalBookings) },
    { label: "Total Amount", value: fmtBDT(data.summary.totalAmount) },
    { label: "Paid", value: fmtBDT(data.summary.totalPaid) },
    { label: "Due", value: fmtBDT(data.summary.totalDue), highlight: data.summary.totalDue > 0 },
  ];
  y = addSummaryCards(doc, y, cards);

  // Deposit & Commission summary bar
  y = addTotalsBar(doc, y, [
    `Deposit: ${fmtBDT(data.summary.totalDeposit)}`,
    `Commission: ${fmtBDT(data.summary.totalCommission)}`,
    `Comm. Paid: ${fmtBDT(data.summary.commissionPaid)}`,
    `Comm. Due: ${fmtBDT(data.summary.commissionDue)}`,
  ]);

  // Bookings table
  if (data.bookings.length > 0) {
    y = addSectionTitle(doc, y, "Bookings");
    y = addRawTable(doc, {
      startY: y,
      head: ["Tracking ID", "Guest", "Package", "Total", "Paid", "Due", "Status"],
      body: data.bookings.map(b => [b.tracking_id, b.guest_name, b.package_name, formatBDT(b.total), formatBDT(b.paid), formatBDT(b.due), b.status]),
    });
  }

  // Moallem Payments
  if (data.moallemPayments.length > 0) {
    y = addSectionTitle(doc, y, "Moallem Payments (Deposits)");
    y = addRawTable(doc, {
      startY: y,
      head: ["Amount", "Date", "Method", "Notes"],
      body: data.moallemPayments.map(p => [formatBDT(p.amount), fmtDate(p.date), p.method, p.notes || "—"]),
    });
  }

  // Commission Payments
  if (data.commissionPayments.length > 0) {
    y = addSectionTitle(doc, y, "Commission Payments");
    y = addRawTable(doc, {
      startY: y,
      head: ["Amount", "Date", "Method", "Notes"],
      body: data.commissionPayments.map(p => [formatBDT(p.amount), fmtDate(p.date), p.method, p.notes || "—"]),
    });
  }

  // Signature & Footer
  addSignatureBlock(doc, sig, y);
  addPdfFooter(doc, cfg, { showPageNumbers: true });
  doc.save(buildFileName("Moallem", data.name));
}

// ── Supplier Agent Profile PDF ──
export interface SupplierPdfData {
  agent_name: string;
  company_name?: string | null;
  phone?: string | null;
  address?: string | null;
  status: string;
  notes?: string | null;
  items?: { description: string; quantity: number; unit_price: number; total_amount: number }[];
  bookings: { tracking_id: string; guest_name: string; package_name: string; total: number; cost: number; paid_to_supplier: number; supplier_due: number; status: string }[];
  agentPayments: { amount: number; date: string; method: string; notes?: string | null; category?: string }[];
  contracts?: { contract_amount: number; pilgrim_count: number; total_paid: number; total_due: number; created_at: string }[];
  contractPayments?: { amount: number; payment_date: string; payment_method: string; note?: string | null }[];
  summary: { totalBookings: number; totalTravelers: number; contractedHajji: number; totalPaid: number; totalDue: number; totalBilled: number };
}

export async function generateSupplierPdf(data: SupplierPdfData, _company: CompanyInfo) {
  const { doc, logoBase64, sig, qrDataUrl, cfg } = await initPdf();

  let y = await addPdfHeader(doc, cfg, logoBase64, qrDataUrl);
  addWatermark(doc, getWatermarkStatus(data.summary.totalPaid, data.summary.totalDue));

  y = addTitleBlock(doc, y, "Supplier Agent Report", data.status);

  // Info box
  const fields: InfoField[] = [
    { label: "Agent Name", value: data.agent_name },
    { label: "Company", value: data.company_name || "N/A" },
    { label: "Phone", value: data.phone || "N/A" },
    { label: "Status", value: data.status },
    { label: "Address", value: data.address || "N/A" },
  ];
  y = await addInfoBox(doc, y, fields, "Supplier Details");

  // Summary cards
  const cards: SummaryCard[] = [
    { label: "Contracted Hajji", value: String(data.summary.contractedHajji) },
    { label: "Total Billed", value: fmtBDT(data.summary.totalBilled) },
    { label: "Total Paid", value: fmtBDT(data.summary.totalPaid) },
    { label: "Total Due", value: fmtBDT(data.summary.totalDue), highlight: data.summary.totalDue > 0 },
  ];
  y = addSummaryCards(doc, y, cards);

  // Service Items
  if (data.items && data.items.length > 0) {
    y = addSectionTitle(doc, y, "Service Items");
    const itemsTotal = data.items.reduce((s, i) => s + i.total_amount, 0);
    y = addRawTable(doc, {
      startY: y,
      head: ["SL", "Description", "Qty", "Unit Price", "Total"],
      body: [
        ...data.items.map((item, i) => [String(i + 1), item.description, String(item.quantity), formatBDT(item.unit_price), formatBDT(item.total_amount)]),
      ],
      foot: [["", "", "", "Grand Total", formatBDT(itemsTotal)]],
    });
  }

  // Bookings
  if (data.bookings.length > 0) {
    y = addSectionTitle(doc, y, "Bookings");
    y = addRawTable(doc, {
      startY: y,
      head: ["Tracking ID", "Guest", "Package", "Total", "Cost", "Paid", "Due", "Status"],
      body: data.bookings.map(b => [b.tracking_id, b.guest_name, b.package_name, formatBDT(b.total), formatBDT(b.cost), formatBDT(b.paid_to_supplier), formatBDT(b.supplier_due), b.status]),
      fontSize: 6.5,
    });
  }

  // Payments
  if (data.agentPayments.length > 0) {
    y = addSectionTitle(doc, y, "Payments to Supplier");
    y = addRawTable(doc, {
      startY: y,
      head: ["Category", "Amount", "Date", "Method", "Notes"],
      body: data.agentPayments.map(p => [p.category || "—", formatBDT(p.amount), fmtDate(p.date), p.method, p.notes || "—"]),
    });
  }

  // Contracts
  if (data.contracts && data.contracts.length > 0) {
    y = addSectionTitle(doc, y, "Contracts");
    y = addRawTable(doc, {
      startY: y,
      head: ["Date", "Pilgrim Count", "Contract Amount", "Paid", "Due"],
      body: data.contracts.map(c => [fmtDate(c.created_at), String(c.pilgrim_count), formatBDT(c.contract_amount), formatBDT(c.total_paid), formatBDT(c.total_due)]),
    });
  }

  // Contract Payments
  if (data.contractPayments && data.contractPayments.length > 0) {
    y = addSectionTitle(doc, y, "Contract Payments");
    y = addRawTable(doc, {
      startY: y,
      head: ["Amount", "Date", "Method", "Note"],
      body: data.contractPayments.map(p => [formatBDT(p.amount), fmtDate(p.payment_date), p.payment_method || "cash", p.note || "—"]),
    });
  }

  addSignatureBlock(doc, sig, y);
  addPdfFooter(doc, cfg, { showPageNumbers: true });
  doc.save(buildFileName("Supplier", data.agent_name));
}

// ── Customer Profile PDF ──
export interface CustomerPdfData {
  full_name: string;
  phone?: string | null;
  email?: string | null;
  passport_number?: string | null;
  nid_number?: string | null;
  address?: string | null;
  date_of_birth?: string | null;
  emergency_contact?: string | null;
  bookings: { tracking_id: string; package_name: string; total: number; paid: number; due: number; status: string; date: string }[];
  payments: { amount: number; date: string; method: string; status: string; installment: number | null; tracking_id: string }[];
  summary: { totalBookings: number; totalAmount: number; totalPaid: number; totalDue: number; totalExpenses: number; profit: number };
}

export async function generateCustomerPdf(data: CustomerPdfData, _company: CompanyInfo) {
  const { doc, logoBase64, sig, qrDataUrl, cfg } = await initPdf();

  let y = await addPdfHeader(doc, cfg, logoBase64, qrDataUrl);
  addWatermark(doc, getWatermarkStatus(data.summary.totalPaid, data.summary.totalDue));

  y = addTitleBlock(doc, y, "Customer Report");

  // Info box
  const fields: InfoField[] = [
    { label: "Name", value: data.full_name || "N/A" },
    { label: "Phone", value: data.phone || "N/A" },
    { label: "Email", value: data.email || "N/A" },
    { label: "Passport", value: data.passport_number || "N/A" },
    { label: "NID", value: data.nid_number || "N/A" },
    { label: "Address", value: data.address || "N/A" },
  ];
  y = await addInfoBox(doc, y, fields, "Customer Details");

  // Summary cards
  const cards: SummaryCard[] = [
    { label: "Bookings", value: String(data.summary.totalBookings) },
    { label: "Total Amount", value: fmtBDT(data.summary.totalAmount) },
    { label: "Total Paid", value: fmtBDT(data.summary.totalPaid) },
    { label: "Due", value: fmtBDT(data.summary.totalDue), highlight: data.summary.totalDue > 0 },
  ];
  y = addSummaryCards(doc, y, cards);


  // Bookings table
  if (data.bookings.length > 0) {
    y = addSectionTitle(doc, y, "Bookings");
    y = addRawTable(doc, {
      startY: y,
      head: ["Tracking ID", "Package", "Date", "Total", "Paid", "Due", "Status"],
      body: data.bookings.map(b => [b.tracking_id, b.package_name, fmtDate(b.date), formatBDT(b.total), formatBDT(b.paid), formatBDT(b.due), b.status]),
    });
  }

  // Payments table
  if (data.payments.length > 0) {
    y = addSectionTitle(doc, y, "Payment History");
    y = addRawTable(doc, {
      startY: y,
      head: ["#", "Booking", "Amount", "Date", "Method", "Status"],
      body: data.payments.map(p => [String(p.installment || "—"), p.tracking_id, formatBDT(p.amount), fmtDate(p.date), p.method || "—", p.status]),
    });
  }

  addSignatureBlock(doc, sig, y);
  addPdfFooter(doc, cfg, { showPageNumbers: true });
  doc.save(buildFileName("Customer", data.full_name || "Unknown"));
}

// ── Get company info from CMS ──
export async function getCompanyInfoForPdf(): Promise<CompanyInfo> {
  const cfg = await getPdfCompanyConfig();
  return {
    name: cfg.company_name,
    phone: cfg.phone,
    email: cfg.email,
    address: cfg.address,
  };
}
