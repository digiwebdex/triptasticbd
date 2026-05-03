// SSLCommerz Payment Gateway integration
// Sandbox docs: https://developer.sslcommerz.com/doc/v4/
const { query } = require('../config/database');

const STORE_ID = process.env.SSLCZ_STORE_ID || 'testbox';
const STORE_PASSWORD = process.env.SSLCZ_STORE_PASSWORD || 'qwerty';
const IS_LIVE = String(process.env.SSLCZ_IS_LIVE || 'false').toLowerCase() === 'true';

const BASE_URL = IS_LIVE
  ? 'https://securepay.sslcommerz.com'
  : 'https://sandbox.sslcommerz.com';

const INIT_URL = `${BASE_URL}/gwprocess/v4/api.php`;
const VALIDATE_URL = `${BASE_URL}/validator/api/validationserverAPI.php`;

// Initiate session — returns GatewayPageURL for redirect
async function initSession({ tran_id, amount, customer, urls, productName }) {
  const body = new URLSearchParams({
    store_id: STORE_ID,
    store_passwd: STORE_PASSWORD,
    total_amount: String(amount),
    currency: 'BDT',
    tran_id,
    success_url: urls.success,
    fail_url: urls.fail,
    cancel_url: urls.cancel,
    ipn_url: urls.ipn,
    cus_name: customer.name || 'Customer',
    cus_email: customer.email || 'noreply@triptastic.com',
    cus_add1: customer.address || 'Dhaka',
    cus_city: 'Dhaka',
    cus_country: 'Bangladesh',
    cus_phone: customer.phone || '01700000000',
    shipping_method: 'NO',
    product_name: productName || 'Trip Tastic Booking Payment',
    product_category: 'Service',
    product_profile: 'general',
  });

  const res = await fetch(INIT_URL, {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body,
  });
  const data = await res.json();
  if (data.status !== 'SUCCESS') {
    throw new Error(`SSLCommerz init failed: ${data.failedreason || JSON.stringify(data)}`);
  }
  return data; // contains GatewayPageURL, sessionkey
}

// Validate transaction with SSLCommerz (server-to-server) before marking paid
async function validateTransaction(val_id) {
  const url = `${VALIDATE_URL}?val_id=${encodeURIComponent(val_id)}&store_id=${STORE_ID}&store_passwd=${STORE_PASSWORD}&format=json`;
  const res = await fetch(url);
  const data = await res.json();
  return data;
}

// Mark session paid + create payments row + auto-trigger updates booking via existing trigger
async function markSessionPaid(session, gatewayData) {
  // Create payments row (status=completed → triggers update bookings paid_amount, due_amount, accounts)
  const paymentMethod = (gatewayData.card_type || 'online').toString().toLowerCase().includes('bkash')
    ? 'bkash'
    : (gatewayData.card_type || '').toLowerCase().includes('nagad')
      ? 'nagad'
      : 'online';

  const paymentRes = await query(
    `INSERT INTO payments (booking_id, user_id, customer_id, amount, payment_method, status, paid_at, transaction_id, notes)
     VALUES ($1, $2, NULL, $3, $4, 'completed', now(), $5, $6) RETURNING id`,
    [
      session.booking_id,
      session.user_id || '00000000-0000-0000-0000-000000000000',
      session.amount,
      paymentMethod,
      gatewayData.bank_tran_id || gatewayData.tran_id || session.tran_id,
      `Online payment via SSLCommerz (${gatewayData.card_issuer || gatewayData.card_type || 'gateway'})`,
    ]
  );
  const paymentId = paymentRes.rows[0].id;

  await query(
    `UPDATE online_payment_sessions SET status='success', gateway_response=$1, payment_id=$2, updated_at=now() WHERE id=$3`,
    [JSON.stringify(gatewayData), paymentId, session.id]
  );

  return paymentId;
}

module.exports = { initSession, validateTransaction, markSessionPaid, IS_LIVE };
