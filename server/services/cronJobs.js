// Cron job implementations — ported from Supabase Edge Functions to node-cron
const { query } = require('../config/database');

// ── helpers ──────────────────────────────────────────────────────────

const toSmsPhone = (value = '') => {
  const digits = String(value).replace(/\D/g, '');
  if (digits.startsWith('880')) return digits;
  if (digits.startsWith('0') && digits.length === 11) return `88${digits}`;
  if (digits.startsWith('1') && digits.length === 10) return `880${digits}`;
  return digits.startsWith('88') ? digits : `88${digits}`;
};

function toCsv(rows) {
  if (!rows || rows.length === 0) return '';
  const headers = Object.keys(rows[0]);
  const lines = [headers.join(',')];
  for (const row of rows) {
    const values = headers.map((h) => {
      const val = row[h];
      if (val === null || val === undefined) return '';
      const str = typeof val === 'object' ? JSON.stringify(val) : String(val);
      if (str.includes(',') || str.includes('"') || str.includes('\n')) {
        return `"${str.replace(/"/g, '""')}"`;
      }
      return str;
    });
    lines.push(values.join(','));
  }
  return lines.join('\n');
}

async function sendResendEmail({ to, subject, html, attachments = [] }) {
  const apiKey = process.env.RESEND_API_KEY;
  if (!apiKey) throw new Error('RESEND_API_KEY not configured');
  const from = process.env.NOTIFICATION_FROM_EMAIL || 'backup@resend.dev';

  const payload = { from, to: Array.isArray(to) ? to : [to], subject, html };
  if (attachments.length) {
    payload.attachments = attachments.map((a) => ({
      filename: a.filename,
      content: Buffer.from(a.content).toString('base64'),
    }));
  }

  const res = await fetch('https://api.resend.com/emails', {
    method: 'POST',
    headers: { Authorization: `Bearer ${apiKey}`, 'Content-Type': 'application/json' },
    body: JSON.stringify(payload),
  });
  const data = await res.json();
  if (!res.ok) throw new Error(`Resend error: ${JSON.stringify(data)}`);
  return data;
}

async function sendBulkSms(number, message) {
  const apiKey = process.env.BULKSMSBD_API_KEY;
  const senderId = process.env.BULKSMSBD_SENDER_ID || '';
  if (!apiKey) throw new Error('BULKSMSBD_API_KEY not configured');

  const url = `https://bulksmsbd.net/api/smsapi?api_key=${encodeURIComponent(apiKey)}&type=text&number=${encodeURIComponent(number)}&senderid=${encodeURIComponent(senderId)}&message=${encodeURIComponent(message)}`;
  const res = await fetch(url);
  const text = await res.text();
  return { ok: res.ok, status: res.status, text };
}

// ── 1. check-due-alerts ──────────────────────────────────────────────

async function runCheckDueAlerts() {
  const startedAt = Date.now();
  const today = new Date().toISOString().slice(0, 10);
  console.log(`[check-due-alerts] start ${today}`);

  const results = { tickets: 0, visa: 0, refunds: 0, notified: 0 };

  // Overdue ticket bookings
  const ticketsRes = await query(
    `SELECT id, invoice_no, passenger_name, billing_name, customer_due, expected_collection_date
     FROM ticket_bookings
     WHERE customer_due > 0 AND status = 'active'
       AND expected_collection_date IS NOT NULL
       AND expected_collection_date < $1`,
    [today]
  );
  results.tickets = ticketsRes.rows.length;

  // Overdue visa applications
  const visaRes = await query(
    `SELECT id, invoice_no, applicant_name, billing_name, customer_due, expected_collection_date
     FROM visa_applications
     WHERE customer_due > 0 AND status = 'active'
       AND expected_collection_date IS NOT NULL
       AND expected_collection_date < $1`,
    [today]
  );
  results.visa = visaRes.rows.length;

  // Overdue ticket refunds
  const refundRes = await query(
    `SELECT id, invoice_no, passenger_name, billing_name, due, refund_date
     FROM ticket_refunds
     WHERE due > 0 AND status = 'active'`,
    []
  );
  results.refunds = refundRes.rows.length;

  const allAlerts = [
    ...ticketsRes.rows.map((t) => ({ type: 'ticket', ...t, name: t.billing_name || t.passenger_name, due: t.customer_due })),
    ...visaRes.rows.map((v) => ({ type: 'visa', ...v, name: v.billing_name || v.applicant_name, due: v.customer_due })),
    ...refundRes.rows.map((r) => ({ type: 'refund', ...r, name: r.billing_name || r.passenger_name })),
  ];

  for (const alert of allAlerts) {
    await query(
      `INSERT INTO notification_logs (user_id, event_type, channel, recipient, message, status)
       VALUES ($1, $2, $3, $4, $5, $6)`,
      [
        '00000000-0000-0000-0000-000000000000',
        'due_alert',
        'system',
        alert.name || 'unknown',
        `Overdue ${alert.type} invoice ${alert.invoice_no}: ${alert.name} owes ${alert.due} BDT`,
        'logged',
      ]
    );
    results.notified++;
  }

  console.log(`[check-due-alerts] done in ${Date.now() - startedAt}ms — tickets=${results.tickets} visa=${results.visa} refunds=${results.refunds} notified=${results.notified}`);
  return { success: true, ...results, date: today };
}

// ── 2. daily-backup ──────────────────────────────────────────────────

const BACKUP_TABLES = [
  'profiles', 'bookings', 'booking_members', 'booking_documents', 'payments',
  'packages', 'installment_plans', 'hotels', 'hotel_rooms', 'hotel_bookings',
  'moallems', 'moallem_payments', 'moallem_commission_payments',
  'supplier_agents', 'supplier_agent_payments', 'expenses', 'transactions',
  'accounts', 'financial_summary', 'notification_logs', 'notification_settings',
  'user_roles', 'site_content', 'company_settings', 'blog_posts', 'cms_versions',
];

async function runDailyBackup() {
  const startedAt = Date.now();
  const today = new Date().toISOString().split('T')[0];
  console.log(`[daily-backup] start ${today}`);

  const attachments = [];
  const tableStats = [];

  for (const table of BACKUP_TABLES) {
    try {
      const res = await query(`SELECT * FROM ${table}`);
      const rows = res.rows || [];
      tableStats.push({ name: table, rows: rows.length });
      if (rows.length > 0) {
        const csv = toCsv(rows);
        attachments.push({ filename: `${table}_${today}.csv`, content: csv });
      }
    } catch (e) {
      console.warn(`[daily-backup] error fetching ${table}:`, e.message);
      tableStats.push({ name: table, rows: -1 });
    }
  }

  const summaryHtml = `
    <h2>📦 Daily Database Backup — ${today}</h2>
    <p>TRIP TASTIC — সকল টেবিলের CSV ব্যাকআপ</p>
    <table border="1" cellpadding="6" cellspacing="0" style="border-collapse:collapse; font-family:monospace; font-size:13px;">
      <tr style="background:#1a1a2e; color:#fff;"><th>Table</th><th>Rows</th></tr>
      ${tableStats.map((t) => `<tr><td>${t.name}</td><td style="text-align:right">${t.rows === -1 ? '⚠️ Error' : t.rows}</td></tr>`).join('')}
    </table>
    <p style="margin-top:16px; color:#666; font-size:12px;">Auto-generated by TRIP TASTIC backup system</p>
  `;

  try {
    await sendResendEmail({
      to: process.env.BACKUP_EMAIL || 'digiwebdex@gmail.com',
      subject: `📦 TRIP TASTIC Daily Backup — ${today}`,
      html: summaryHtml,
      attachments,
    });
    console.log(`[daily-backup] email sent in ${Date.now() - startedAt}ms — tables=${tableStats.length} attachments=${attachments.length}`);
    return { success: true, tables: tableStats.length, attachments: attachments.length };
  } catch (e) {
    console.error('[daily-backup] email failed:', e.message);
    return { success: false, error: e.message };
  }
}

// ── 3. daily-summary-sms ─────────────────────────────────────────────

async function runDailySummarySms() {
  const startedAt = Date.now();
  const today = new Date().toISOString().split('T')[0];
  console.log(`[daily-summary-sms] start ${today}`);

  // Today's income: completed customer payments
  const paymentsRes = await query(
    `SELECT amount FROM payments WHERE status = 'completed' AND paid_at >= $1 AND paid_at <= $2`,
    [`${today}T00:00:00`, `${today}T23:59:59`]
  );
  const todayIncome = (paymentsRes.rows || []).reduce((s, p) => s + Number(p.amount), 0);

  // Today's moallem payments
  const moallemRes = await query(
    `SELECT amount FROM moallem_payments WHERE date >= $1 AND date <= $2`,
    [today, today]
  );
  const todayMoallemIncome = (moallemRes.rows || []).reduce((s, p) => s + Number(p.amount), 0);

  // Today's supplier payments
  const supplierRes = await query(
    `SELECT amount FROM supplier_agent_payments WHERE date >= $1 AND date <= $2`,
    [today, today]
  );
  const todaySupplierPaid = (supplierRes.rows || []).reduce((s, p) => s + Number(p.amount), 0);

  // Overall customer due
  const bookingsRes = await query(`SELECT due_amount FROM bookings`);
  const totalCustomerDue = (bookingsRes.rows || []).reduce((s, b) => s + Number(b.due_amount || 0), 0);

  // Moallem due
  const moallemsRes = await query(`SELECT total_due FROM moallems`);
  const totalMoallemDue = (moallemsRes.rows || []).reduce((s, m) => s + Number(m.total_due || 0), 0);

  // Supplier due
  const supplierDueRes = await query(`SELECT supplier_due FROM bookings`);
  const totalSupplierDue = (supplierDueRes.rows || []).reduce((s, b) => s + Number(b.supplier_due || 0), 0);

  const fmt = (n) => n.toLocaleString('en-BD');
  const ownerPhone = process.env.OWNER_PHONE || '01601505050';

  const message = [
    `TRIP TASTIC Daily Summary (${today})`,
    '',
    `Today Income: ৳${fmt(todayIncome + todayMoallemIncome)}`,
    `Today Supplier Paid: ৳${fmt(todaySupplierPaid)}`,
    '',
    `Customer Due: ৳${fmt(totalCustomerDue)}`,
    `Moallem Due: ৳${fmt(totalMoallemDue)}`,
    `Supplier Due: ৳${fmt(totalSupplierDue)}`,
    '',
    `Total Bookings Due: ৳${fmt(totalCustomerDue)}`,
  ].join('\n');

  try {
    const smsRes = await sendBulkSms(toSmsPhone(ownerPhone), message);
    const status = smsRes.ok ? 'sent' : 'failed';

    await query(
      `INSERT INTO notification_logs (user_id, event_type, channel, recipient, subject, message, status, error_detail)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8)`,
      [
        '9c56194a-b0f9-4878-ac57-e97371acd199',
        'daily_summary',
        'sms',
        ownerPhone,
        'Daily Summary',
        message,
        status,
        smsRes.ok ? null : smsRes.text,
      ]
    );

    console.log(`[daily-summary-sms] done in ${Date.now() - startedAt}ms — status=${status}`);
    return { success: true, status, message };
  } catch (e) {
    console.error('[daily-summary-sms] failed:', e.message);
    return { success: false, error: e.message };
  }
}

module.exports = {
  runCheckDueAlerts,
  runDailyBackup,
  runDailySummarySms,
};
