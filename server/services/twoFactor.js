// 2FA service — supports SMS OTP and TOTP (authenticator app)
const speakeasy = require('speakeasy');
const QRCode = require('qrcode');
const { query } = require('../config/database');

const OTP_TTL_MIN = 10;

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
  return res.ok;
}

// Get current 2FA settings for an admin
async function getSettings(userId) {
  const { rows } = await query('SELECT * FROM admin_2fa WHERE user_id = $1', [userId]);
  return rows[0] || null;
}

// === SMS OTP ===
async function sendSmsOtp(userId, phone) {
  const code = String(Math.floor(100000 + Math.random() * 900000));
  const expiresAt = new Date(Date.now() + OTP_TTL_MIN * 60 * 1000).toISOString();
  await query('INSERT INTO admin_2fa_codes (user_id, code, expires_at) VALUES ($1, $2, $3)', [userId, code, expiresAt]);
  const number = toSmsPhone(phone);
  await sendSms(number, `TRIP TASTIC Admin login code: ${code} (valid for ${OTP_TTL_MIN} min)`);
  return true;
}

async function verifySmsOtp(userId, code) {
  const { rows } = await query(
    `SELECT id FROM admin_2fa_codes
     WHERE user_id = $1 AND code = $2 AND verified = false AND expires_at >= now()
     ORDER BY created_at DESC LIMIT 1`,
    [userId, code]
  );
  if (!rows[0]) return false;
  await query('UPDATE admin_2fa_codes SET verified = true WHERE id = $1', [rows[0].id]);
  return true;
}

// === TOTP ===
async function generateTotpSetup(userId, email) {
  const secret = speakeasy.generateSecret({
    name: `TRIP TASTIC Admin (${email})`,
    issuer: 'TRIP TASTIC',
    length: 20,
  });
  // Store as pending — user must verify before enabling
  await query(
    `INSERT INTO admin_2fa (user_id, totp_secret_pending, updated_at)
     VALUES ($1, $2, now())
     ON CONFLICT (user_id) DO UPDATE SET totp_secret_pending = EXCLUDED.totp_secret_pending, updated_at = now()`,
    [userId, secret.base32]
  );
  const qrDataUrl = await QRCode.toDataURL(secret.otpauth_url);
  return { secret: secret.base32, otpauth_url: secret.otpauth_url, qr: qrDataUrl };
}

function verifyTotpCode(secret, token) {
  return speakeasy.totp.verify({ secret, encoding: 'base32', token, window: 1 });
}

async function confirmTotpEnable(userId, token) {
  const settings = await getSettings(userId);
  if (!settings?.totp_secret_pending) throw new Error('No pending TOTP setup');
  if (!verifyTotpCode(settings.totp_secret_pending, token)) return false;
  await query(
    `UPDATE admin_2fa
       SET totp_secret = totp_secret_pending,
           totp_secret_pending = NULL,
           totp_enabled = true,
           updated_at = now()
     WHERE user_id = $1`,
    [userId]
  );
  return true;
}

async function disableTotp(userId) {
  await query(
    `UPDATE admin_2fa SET totp_secret = NULL, totp_secret_pending = NULL, totp_enabled = false, updated_at = now() WHERE user_id = $1`,
    [userId]
  );
}

async function setSmsEnabled(userId, enabled, phone) {
  await query(
    `INSERT INTO admin_2fa (user_id, sms_enabled, sms_phone, updated_at)
     VALUES ($1, $2, $3, now())
     ON CONFLICT (user_id) DO UPDATE SET sms_enabled = EXCLUDED.sms_enabled, sms_phone = COALESCE(EXCLUDED.sms_phone, admin_2fa.sms_phone), updated_at = now()`,
    [userId, !!enabled, phone || null]
  );
}

module.exports = {
  getSettings,
  sendSmsOtp,
  verifySmsOtp,
  generateTotpSetup,
  verifyTotpCode,
  confirmTotpEnable,
  disableTotp,
  setSmsEnabled,
};
