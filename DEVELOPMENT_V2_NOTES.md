# Development v2

Added a **new, undeployed** Cloudflare Worker backend scaffold in `backend/`, including Firebase ID-token verification, D1 orders, private R2 PDF uploads, server-priced orders, admin status permissions, and Razorpay server-side order creation and payment verification.

**Not a finished app**: existing Flutter screens/services use an older API contract and must be migrated; no production deployment, APK build, or live payment testing was performed. See `backend/README.md` for setup and remaining security work.
