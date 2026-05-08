// Stub handlers for converted edge functions.
// Each function below mirrors a Supabase Edge Function from supabase/functions/.
// TODO: Port the business logic from backup/supabase_full_backup/supabase_source/functions/<name>/index.ts
//       Replace Deno+Supabase calls with `require('../db').query(...)` and Node.js libraries.
//
// Contract: each module exports an async (req, res) Express handler.
//           Input is read from req.body, output is JSON.

const stub = (name) => async (_req, res) => {
  res.status(501).json({
    error: `${name} not yet ported from supabase/functions/${name}/index.ts`,
    hint: 'See docs/MIGRATION_REPORT.md for the audit and conversion plan.',
  });
};

// One file per endpoint — stubs created for the remaining 15 functions.
module.exports = stub;
