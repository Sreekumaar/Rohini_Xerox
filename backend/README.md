# Rohini Xerox Cloudflare backend (development scaffold)

Requires Node.js, a Cloudflare account with Workers/D1/R2 enabled, and a Firebase project.

1. `cd backend && npm install && npx wrangler login`
2. `npx wrangler d1 create rohini-orders` and `npx wrangler r2 bucket create rohini-documents`.
3. Copy the D1 ID into `wrangler.toml`. Replace the Firebase project ID, admin Firebase UID(s), and Razorpay **public** key ID.
4. `npx wrangler secret put RAZORPAY_KEY_SECRET` (never add this secret to source code).
5. `npm run db:init` then `npm run deploy`.
6. Configure the Flutter app with the deployed Worker URL and Firebase bearer tokens. **The existing Flutter client is not yet integrated with this new API contract.**

Endpoints: `GET /health`, authenticated `POST /upload` (multipart field `file`), `POST /orders`, `GET /orders`, `GET /orders/:id`, `GET /orders/:id/document`, `POST /orders/:id/payment-order`, `POST /orders/:id/verify-payment`, admin `PUT /orders/:id/status`.

All private endpoints require `Authorization: Bearer <Firebase ID token>`. The server calculates prices (currently placeholder ₹2/page B&W, ₹10/page colour, ₹60 delivery), not the client. Confirm actual rates and delivery coverage before production.

Production hardening remaining: payment webhooks and idempotency, file-content validation, upload rate limits, explicit allowed-origin CORS for web clients, audit logging, delivery address/phone validation, order state transitions, fraud controls, retention/deletion, and end-to-end tests. Do not accept live payments before completing these items and testing Razorpay test mode.
