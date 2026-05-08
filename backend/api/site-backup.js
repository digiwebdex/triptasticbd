// POST /api/site-backup
// MIGRATION STATUS: Already implemented in production backend (server/index.js)
// The real endpoint is POST /api/backup/create — see server/index.js lines ~645-668.
// This stub file is kept only for reference during the migration; it is NOT used by the live server.
//
// Live implementation:
//   - Backs up all BACKUP_TABLES to server/backups/backup_<timestamp>.json
//   - Uses direct PostgreSQL queries (query('SELECT * FROM <table>'))
//   - Admin-only route protected by authenticate + requireRole('admin')
//
// Frontend caller:
//   src/components/admin/BackupRestoreManager.tsx calls /api/backup/create directly.

module.exports = () => {
  throw new Error('site-backup is implemented in server/index.js at /api/backup/create');
};
