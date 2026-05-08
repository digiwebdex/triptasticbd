// Express router that mounts all converted Supabase Edge Functions.
// Each file in this folder exports an Express handler.
const express = require('express');
const router = express.Router();

const handlers = {
  'verify-invoice':           require('./verify-invoice'),
  'track-booking':            require('./track-booking'),
  'send-otp':                 require('./send-otp'),
  'send-notification':        require('./send-notification'),
  'send-reminder':            require('./send-reminder'),
  'check-due-alerts':         require('./check-due-alerts'),
  'create-guest-booking':     require('./create-guest-booking'),
  'upload-booking-document':  require('./upload-booking-document'),
  'booking-notifications':    require('./booking-notifications'),
  'admin-create-user':        require('./admin-create-user'),
  'admin-manage-user':        require('./admin-manage-user'),
  'daily-backup':             require('./daily-backup'),
  'daily-summary-sms':        require('./daily-summary-sms'),
  'site-backup':              require('./site-backup'),
  'site-restore':             require('./site-restore'),
  'fb-conversions-api':       require('./fb-conversions-api'),
};

for (const [name, handler] of Object.entries(handlers)) {
  router.post(`/${name}`, handler);
}

module.exports = router;
