# Rohini Xerox — offline workflow preview

This source package preserves the existing Flutter application and Cloudflare Worker scaffold, and adds a **separate demo mode** for testing customer print-order entry, delivery details, price estimates, order history, and admin status updates **without deploying services**.

## Run demo

1. Install Flutter and Android SDK.
2. From `Rohini_Xerox/`, run `flutter pub get`.
3. Run `flutter run --dart-define=DEMO_MODE=true`.
4. For a demo APK: `flutter build apk --debug --dart-define=DEMO_MODE=true`.

Demo orders exist in memory only and disappear when the application restarts. The PDF is selected locally but **not uploaded**. No payment is attempted. The admin preview is **not authenticated** and must never be enabled in a production release. The demo pricing (₹2 B&W, ₹10 colour, ₹60 delivery) is illustrative, not a final shop tariff.

## Production path

Run without `DEMO_MODE` only after configuring Firebase, deploying the Worker and D1/R2, reconciling the mobile API payloads with the Worker contract, integrating Razorpay server-created orders and signature verification, and testing security and order lifecycle end-to-end. Keep `RAZORPAY_KEY_SECRET` only in Worker secrets, never in Flutter.

## Known limitations

- Flutter/Android toolchain is not installed in this environment, so the project has **not** been compiled or run here.
- The existing live application and Worker integration are **not complete**.
- No persistent offline database, delivery dispatch provider, live checkout, or customer notification is included in demo mode.
