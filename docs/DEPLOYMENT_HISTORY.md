# Deployment History — Manasik Travel Hub

> Complete deployment timeline, server operations, and infrastructure changes
> **Last Updated:** April 2026

---

## Deployment Timeline

### v3.0.0 - April 2026 (Rebrand & Reset)
- **Action:** Full system rebrand from "RAHE KABA Tours & Travels" to "Manasik Travel Hub".
- **Changes:**
  - Updated all branding assets, logos, and favicons.
  - Reset database to fresh state (cleared bookings, customers, and legacy records).
  - Updated PDF templates, invoice headers, and email signatures.
  - Refreshed SEO metadata, sitemap, and robots.txt.
  - Standardized environment variables for the new domain.
- **Status:** Production Stable.

### v2.5.0 - March 2026
- **Action:** Infrastructure migration to new VPS.
- **Changes:**
  - Setup Dockerized PostgreSQL (port 5433).
  - Configured Nginx reverse proxy for API and Frontend.
  - Implemented PM2 process management for Node.js backend.
  - Configured SSL via Certbot.

### v2.0.0 - January 2026
- **Action:** Major feature update.
- **Changes:**
  - Added PDF generation module.
  - Integrated Supabase for real-time data.
  - Implemented role-based access control (RBAC).

### v1.0.0 - 2025
- **Action:** Initial project launch.
- **Changes:**
  - Core setup of React frontend and Express backend.
  - Initial database schema design.
