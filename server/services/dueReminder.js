// Auto Due Reminder service — sends SMS reminders for upcoming/overdue payments
const { query } = require('../config/database');

const toSmsPhone = (value = '') => {
  const digits = String(value).replace(/\D/g, '');
  if (digits.startsWith('880')) return digits;
  if (digits.startsWith('0') && digits.length === 11) return `88${digits}`;
  if (digits.startsWith('1') && digits.length === 10) return `880${digits}`;
  return digits.startsWith('88') ? digits : `88${digits}`;
};

async function sendSms(number, message) {
  const apiKey = process.env.BULKSMSBD_API_KEY || process.env.BULKSMS_API_KEY;
  const senderId = process.env.BULKSMSBD_SENDER_ID || process.env.BULKSMS_SENDER_ID || '8809617618686';
  if (!apiKey) throw new Error('SMS API key not configured');
  const url = `https://bulksmsbd.net/api/smsapi?api_key=${encodeURIComponent(apiKey)}&type=text&number=${encodeURIComponent(number)}&senderid=${encodeURIComponent(senderId)}&message=${encodeURIComponent(message)}`;
  const res = await fetch(url);
  const text = await res.text();
  return { ok: res.ok, status: res.status, text };
}

// Find due/overdue payments that need a reminder.
// Sends:
//   - 3 days before due (upcoming reminder)
//   - On due date
//   - 3 days after due (overdue)
// One reminder per (booking_id, day-bucket) — controlled via notification_logs.
async function runDueReminderJob() {
  const startedAt = Date.now();
  console.log('[due-reminder] job start');

  const sql = `
    SELECT p.id AS payment_id, p.booking_id, p.amount, p.due_date, p.installment_number,
           b.tracking_id, b.guest_name, b.guest_phone, b.user_id,
           prof.full_name AS profile_name, prof.phone AS profile_phone
    FROM payments p
    JOIN bookings b ON b.id = p.booking_id
    LEFT JOIN profiles prof ON prof.user_id = b.user_id
    WHERE p.status = 'pending'
      AND p.due_date IS NOT NULL
      AND b.status NOT IN ('cancelled','deleted')
      AND p.due_date BETWEEN (CURRENT_DATE - INTERVAL '14 days') AND (CURRENT_DATE + INTERVAL '7 days')
  `;
  const { rows } = await query(sql);

  let sent = 0, skipped = 0, failed = 0;

  for (const r of rows) {
    const phone = r.profile_phone || r.guest_phone;
    if (!phone) { skipped++; continue; }

    const due = new Date(r.due_date);
    const today = new Date(); today.setHours(0,0,0,0);
    const diffDays = Math.round((due.getTime() - today.getTime()) / 86400000);

    let bucket = null;
    if (diffDays === 3) bucket = 'upcoming-3d';
    else if (diffDays === 0) bucket = 'due-today';
    else if (diffDays === -3) bucket = 'overdue-3d';
    else if (diffDays === -7) bucket = 'overdue-7d';
    else { skipped++; continue; }

    const eventType = `due_reminder_${bucket}`;

    // Skip if already sent today for this booking + bucket
    const existing = await query(
      `SELECT id FROM notification_logs
       WHERE booking_id = $1 AND event_type = $2 AND channel = 'sms'
         AND created_at >= CURRENT_DATE LIMIT 1`,
      [r.booking_id, eventType]
    );
    if (existing.rows[0]) { skipped++; continue; }

    const name = r.profile_name || r.guest_name || 'Customer';
    const tk = r.tracking_id || '';
    const amt = Number(r.amount || 0).toLocaleString('en-IN');
    let message;
    if (bucket === 'upcoming-3d') {
      message = `TRIP TASTIC: Dear ${name}, your payment of BDT ${amt} for booking ${tk} is due in 3 days. Please pay on time. Call: 09617618686`;
    } else if (bucket === 'due-today') {
      message = `TRIP TASTIC: Dear ${name}, your payment of BDT ${amt} for booking ${tk} is due TODAY. Please pay now. Call: 09617618686`;
    } else if (bucket === 'overdue-3d') {
      message = `TRIP TASTIC: Dear ${name}, payment of BDT ${amt} for booking ${tk} is OVERDUE by 3 days. Please pay immediately. Call: 09617618686`;
    } else {
      message = `TRIP TASTIC: Dear ${name}, payment of BDT ${amt} for booking ${tk} is OVERDUE by 7+ days. Final reminder. Call: 09617618686`;
    }

    const smsNumber = toSmsPhone(phone);
    let status = 'sent';
    let errorDetail = null;
    try {
      const smsRes = await sendSms(smsNumber, message);
      if (!smsRes.ok) { status = 'failed'; errorDetail = smsRes.text?.slice(0, 200); failed++; }
      else sent++;
    } catch (e) {
      status = 'failed'; errorDetail = e.message; failed++;
    }

    await query(
      `INSERT INTO notification_logs (user_id, booking_id, payment_id, event_type, channel, recipient, message, status, error_detail)
       VALUES ($1, $2, $3, $4, 'sms', $5, $6, $7, $8)`,
      [r.user_id || '00000000-0000-0000-0000-000000000000', r.booking_id, r.payment_id, eventType, smsNumber, message, status, errorDetail]
    );
  }

  const duration = Date.now() - startedAt;
  console.log(`[due-reminder] done in ${duration}ms — sent=${sent} skipped=${skipped} failed=${failed} (scanned=${rows.length})`);
  return { sent, skipped, failed, scanned: rows.length };
}

module.exports = { runDueReminderJob };
