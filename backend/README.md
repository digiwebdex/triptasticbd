# Triptastic Backend API

This folder is the **target structure** for the self-hosted backend.

## Status

The live production backend currently lives at `../server/` (Node.js/Express, PM2-managed, port 3045).
This folder mirrors the planned final layout and contains:

- `db/` — PostgreSQL connection pool (`pg`) used by all endpoints.
- `api/` — Converted Supabase Edge Functions exposed as `/api/<function-name>`.

## Migration plan

See `../docs/MIGRATION_REPORT.md` → "Edge function audit" for the conversion checklist.

Each converted function in `api/` follows the same contract as the original Supabase Edge Function:

| Original | New endpoint | Method |
|---|---|---|
| `supabase.functions.invoke('verify-invoice')` | `POST /api/verify-invoice` | POST |
| `supabase.functions.invoke('track-booking')` | `POST /api/track-booking` | POST |
| `supabase.functions.invoke('send-otp')` | `POST /api/send-otp` | POST |
| ... | ... | ... |

## Wiring into Express

```js
const express = require('express');
const app = express();

// Mount converted edge functions
app.use('/api', require('./api'));

app.listen(process.env.PORT || 3001);
```
