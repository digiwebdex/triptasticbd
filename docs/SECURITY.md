# Security Documentation — Manasik Travel Hub

> Security measures, authentication, authorization, and best practices
> **Last Updated:** April 2026

## 1. Authentication & Authorization
- **JWT Implementation:** All API requests are protected via JSON Web Tokens (JWT). Tokens are signed using a secure `JWT_SECRET` and `JWT_REFRESH_SECRET`.
- **Role-Based Access Control (RBAC):** The system enforces strict role separation:
  - `super_admin`: Full system access.
  - `admin`: Management of bookings, packages, and users.
  - `staff`: Operational access for processing bookings.
  - `customer`: Limited access to personal profile and booking history.
- **Session Management:** Sessions are persisted via `localStorage` on the client side and validated against the database on every sensitive request.

## 2. Data Protection
- **Database Security:** PostgreSQL is isolated within a Docker container, accessible only via internal network ports.
- **Environment Variables:** Sensitive credentials (API keys, database URLs, secrets) are stored in `.env` files and are excluded from version control.
- **Input Sanitization:** All user inputs are sanitized on the backend to prevent SQL injection and XSS attacks.

## 3. Infrastructure Security
- **SSL/TLS:** All traffic is encrypted via HTTPS using Let's Encrypt certificates.
- **Firewall:** Nginx acts as a reverse proxy, handling SSL termination and blocking unauthorized access to sensitive paths (e.g., `/admin`, `/api/internal`).
- **Rate Limiting:** Implemented at the Nginx level to prevent brute-force attacks on login and registration endpoints.

## 4. Best Practices for Developers
- **Never commit secrets:** Ensure `.env` is added to `.gitignore`.
- **Dependency Audits:** Regularly run `npm audit` to identify and patch vulnerabilities in project dependencies.
- **Logging:** Sensitive actions (login, password reset, booking modification) are logged in the database for audit trails.

## 5. Incident Response
- In case of a suspected breach, immediately rotate `JWT_SECRET` and `DATABASE_URL` credentials.
- Flush all active sessions by clearing the `refresh_tokens` table in the database.
- Review PM2 logs (`pm2 logs manasik-api`) for suspicious activity patterns.
