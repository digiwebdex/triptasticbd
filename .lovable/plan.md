## PDF System Redesign Plan

### Current State (Audit Summary)
The system already has a solid PDF foundation:
- **invoiceGenerator.ts** (1270 lines) — Individual + Family invoices with QR, watermark, signature, Bengali support
- **entityPdfGenerator.ts** (535 lines) — Moallem, Supplier, Customer profile PDFs
- **reportExport.ts** (405 lines) — Standard + Hajji report PDFs and Excel exports
- **pdfFontLoader.ts** — Bengali canvas bridge
- **pdfQrCode.ts** — QR codes, watermarks, verification IDs
- **pdfSignature.ts** — Dynamic signature/stamp
- **pdfCompanyConfig.ts** — Centralized branding

### What Needs Improvement
1. **Duplicated header/footer logic** across 3 files — needs unified core
2. **Missing PDF types**: Payment Receipt, Expense Voucher, Statement PDFs, Daily Cashbook, Commission Report
3. **Report PDFs lack summary cards** at top
4. **No page numbers** on multi-page reports
5. **No filter summary** shown on reports
6. **Table headers don't repeat** on new pages (autoTable handles this but needs `showHead: 'everyPage'`)

### Implementation Plan (3 Phases)

#### Phase 1: Unified PDF Core (`src/lib/pdfCore.ts`)
Create a single reusable module with:
- `addPdfHeader()` — branded header (logo, tagline, contact, gold bar)
- `addPdfFooter()` — gold bar footer with page numbers
- `addPdfTitle()` — document title badge + status badge
- `addSummaryCards()` — executive summary boxes
- `addFilterSummary()` — report filter display
- `addSignatureBlock()` — signature section
- Constants: GOLD, DARK, LIGHT_BG colors
- Helpers: formatAmount, fmtDate, ensurePageSpace

#### Phase 2: New PDF Document Types
Create missing document generators:
- **Payment Receipt PDF** — single payment receipt for customer
- **Moallem Payment Receipt** — receipt for moallem deposit
- **Supplier Payment Voucher** — voucher for supplier payment
- **Expense Voucher** — company expense voucher
- **Customer Statement** — all transactions for a customer
- **Moallem Statement** — all transactions for a moallem  
- **Supplier Statement** — all transactions for a supplier
- **Daily Cashbook PDF** — daily income/expense log
- **Commission Report PDF** — moallem commission summary
- **Income/Expense/Profit Report PDFs** — financial reports with summary cards

#### Phase 3: Enhance Existing PDFs
- Add page numbers to all multi-page PDFs
- Add `showHead: 'everyPage'` to all autoTable calls
- Add summary cards to report PDFs
- Improve filename generation with dates
- Add filter summary to reports
- Ensure BDT formatting consistency

### Design System
- Primary accent: Gold (#C5A55A / RGB 197,165,90)
- Dark: #232830 (headers, badges)
- Light BG: #FAF9F7 (alternate rows)
- Font: Helvetica + NotoSansBengali for Bengali
- A4 portrait, 14mm margins
- Gold top bar (3mm) + gold bottom bar (16mm)

### Files to Create/Modify
- **NEW**: `src/lib/pdfCore.ts` — unified PDF components
- **MODIFY**: `src/lib/invoiceGenerator.ts` — use pdfCore, add receipt
- **MODIFY**: `src/lib/entityPdfGenerator.ts` — use pdfCore, add statements
- **MODIFY**: `src/lib/reportExport.ts` — use pdfCore, add summary cards, page numbers

Shall I proceed with this plan?