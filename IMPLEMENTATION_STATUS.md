# Rohini Xerox — implementation status

## Changes in this package
- Retain the selected PDF instead of reopening the picker at submission.
- Add customer-facing home-delivery selection and required address.
- Check order creation HTTP response before displaying success.
- Remove hardcoded Razorpay placeholder; read public key from `--dart-define=RAZORPAY_KEY_ID=...`.
- Stop treating an unverified client-side Razorpay callback as confirmed payment.

## Still required before production
1. Implement server-side Razorpay order creation, signature verification and webhooks. Do not trust client-supplied amounts or payment states.
2. Enforce Firebase ID token validation and admin role authorization on Cloudflare Worker endpoints.
3. Compute print and courier prices on the backend; show an approved quote before payment.
4. Confirm Cloudflare R2 private access, upload limits, malware controls and retention policy.
5. Test the Cloudflare Worker and D1 schema against the mobile application.
6. Test Flutter build on a machine with Flutter/Android SDK installed.
7. Add customer order history, address management, delivery tracking and payment retry UI.

This is an incremental source update, not a production-ready release.
