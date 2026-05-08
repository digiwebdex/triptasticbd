// POST /api/verify-invoice
// Converted from supabase/functions/verify-invoice/index.ts
// Looks up a booking by tracking_id and returns safe public fields.
const { query } = require('../db');

module.exports = async function verifyInvoice(req, res) {
  try {
    const { tracking_id } = req.body || {};
    if (!tracking_id || typeof tracking_id !== 'string') {
      return res.status(400).json({ error: 'tracking_id is required' });
    }

    const sql = `
      SELECT b.tracking_id, b.total_amount, b.paid_amount, b.due_amount,
             b.status, b.created_at, b.num_travelers, b.guest_name,
             json_build_object('name', p.name, 'type', p.type) AS packages
      FROM public.bookings b
      LEFT JOIN public.packages p ON p.id = b.package_id
      WHERE b.tracking_id = $1
      LIMIT 1
    `;
    const result = await query(sql, [tracking_id.toUpperCase()]);

    if (result.rowCount === 0) {
      return res.json({ booking: null });
    }
    return res.json({ booking: result.rows[0] });
  } catch (err) {
    console.error('[verify-invoice] error:', err);
    return res.status(500).json({ error: 'Internal error' });
  }
};
