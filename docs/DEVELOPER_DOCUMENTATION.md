# Manasik Travel Hub — Developer Documentation (A-Z)

> **Last Updated:** April 2026
> **Version:** 3.x
> **Repository:** https://github.com/digiwebdex/sakinah-journey-ec91ec18

## Overview
Manasik Travel Hub is a comprehensive travel management platform designed for Hajj & Umrah services. This documentation covers the architecture, setup, and maintenance procedures for the system.

## Tech Stack
- **Frontend:** React, TypeScript, Tailwind CSS, Vite
- **Backend:** Node.js, Express
- **Database:** PostgreSQL (via Supabase/Docker)
- **Authentication:** Supabase Auth
- **PDF Generation:** Puppeteer/wkhtmltopdf

## Setup Instructions
1. Clone the repository.
2. Install dependencies: `npm install`.
3. Configure environment variables in `.env` and `server/.env`.
4. Run development server: `npm run dev`.

## Branding Guidelines
All references to the previous brand "Rahe Kaba" have been removed. The system is now fully rebranded to "Manasik Travel Hub". Ensure all new assets, templates, and documentation follow this identity.

## Maintenance
- **Database:** Use `psql` commands provided in `DEPLOYMENT_COMMANDS.md`.
- **Logs:** Monitor via PM2 logs.
- **Updates:** Pull from `main` branch and rebuild.

## Support
For technical issues, contact the development team at support@manasiktravelhub.com.
