// POST /api/site-restore
// MIGRATION STATUS: Already implemented in production backend (server/index.js)
// The real endpoint is POST /api/backup/restore — see server/index.js lines ~670-746.
// This stub file is kept only for reference during the migration; it is NOT used by the live server.
//
// Live implementation:
//   - Reads backup JSON from server/backups/<fileName>
//   - Supports "full" mode (DELETE all rows then INSERT/UPSERT) and "merge" mode (UPSERT only)
//   - Uses RESTORE_ORDER to respect foreign key constraints
//   - Admin-only route protected by authenticate + requireRole('admin')
//
// Frontend caller:
//   src/components/admin/BackupRestoreManager.tsx calls /api/backup/restore directly.

module.exports = () => {
  throw new Error('site-restore is implemented in server/index.js at /api/backup/restore');
};
