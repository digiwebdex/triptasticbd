// Audit logging middleware — logs admin write operations to audit_logs table
const { query } = require('../config/database');

const SENSITIVE_KEYS = new Set(['password', 'password_hash', 'token', 'refresh_token', 'access_token', 'otp', 'code']);
const sanitize = (obj) => {
  if (!obj || typeof obj !== 'object') return obj;
  const out = Array.isArray(obj) ? [] : {};
  for (const [k, v] of Object.entries(obj)) {
    if (SENSITIVE_KEYS.has(k.toLowerCase())) out[k] = '***';
    else if (v && typeof v === 'object') out[k] = sanitize(v);
    else out[k] = v;
  }
  return out;
};

async function writeAuditLog(entry) {
  try {
    await query(
      `INSERT INTO audit_logs
       (actor_id, actor_email, actor_role, action, entity_type, entity_id, method, path, status_code, ip_address, user_agent, changes, metadata)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13)`,
      [
        entry.actor_id || null,
        entry.actor_email || null,
        entry.actor_role || null,
        entry.action,
        entry.entity_type || null,
        entry.entity_id || null,
        entry.method || null,
        entry.path || null,
        entry.status_code || null,
        entry.ip_address || null,
        entry.user_agent || null,
        JSON.stringify(entry.changes || {}),
        JSON.stringify(entry.metadata || {}),
      ]
    );
  } catch (err) {
    console.error('audit_log insert failed:', err.message);
  }
}

// Express middleware that captures responses and logs writes
function auditMiddleware(req, res, next) {
  const method = req.method;
  if (!['POST', 'PATCH', 'PUT', 'DELETE'].includes(method)) return next();
  if (req.path.startsWith('/api/auth/refresh')) return next();

  const originalJson = res.json.bind(res);
  res.json = (body) => {
    try {
      const status = res.statusCode;
      // Determine entity from URL like /api/<entity>/...
      const segs = req.originalUrl.split('?')[0].split('/').filter(Boolean); // ['api','<entity>',':id'?]
      const entity = segs[1] || null;
      const entityId = (body && body.id) || (segs[2] && /^[\w-]+$/.test(segs[2]) ? segs[2] : null);
      const action = method === 'POST'
        ? (req.path.includes('login') ? 'login' : 'create')
        : method === 'DELETE' ? 'delete' : 'update';

      writeAuditLog({
        actor_id: req.user?.id || null,
        actor_email: req.user?.email || null,
        actor_role: (req.userRoles && req.userRoles[0]) || null,
        action,
        entity_type: entity,
        entity_id: entityId ? String(entityId) : null,
        method,
        path: req.originalUrl.split('?')[0],
        status_code: status,
        ip_address: req.headers['x-forwarded-for']?.split(',')[0]?.trim() || req.ip || null,
        user_agent: req.headers['user-agent'] || null,
        changes: status < 400 ? sanitize(req.body) : { error: body?.error },
      });
    } catch (e) {
      console.error('audit middleware error:', e.message);
    }
    return originalJson(body);
  };
  next();
}

module.exports = { auditMiddleware, writeAuditLog };
