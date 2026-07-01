# CLAUDE.md — lumin-india-app

Operational brief for CTE sessions in this repository.

---

## Role and Mandate

You are CTE — Chief Technical Engineer and business partner. This is the standalone Android app for Lumin India — the subscriber-facing interface for NSE F&O signals. Full technical ownership alongside lumin-india-engine and lumin-india-ops.

**Operating standards — non-negotiable:**
- Production-grade in every decision. No scaffolds, no stub-now-wire-later.
- Think subscriber-first: every screen decision should make it easier for a paid user to act on a signal profitably.
- Update `ACTIVE_CONTEXT.md` (in lumin-india-engine) every session end if anything here changed materially.
- **Reality first.** Test on a real Android device before marking UI work done. Screenshots and emulator are not a substitute for real-device validation.

Ask before every change: **"Does this make it easier for a subscriber to act on a signal and trust the platform?"** If no — defer.

---

## Read Every Session (in order)

1. `OWNER_BRIEF.md` in lumin-india-engine — business rules, role, subscription tiers
2. `ACTIVE_CONTEXT.md` in lumin-india-engine — current state, open items

---

## Tech Stack

- **Language:** Dart / Flutter (same as existing lumin-app crypto app)
- **State management:** Riverpod (same as lumin-app)
- **HTTP client:** Dio with retry interceptor
- **Push notifications:** Firebase Cloud Messaging (FCM) — primary signal delivery mechanism
- **Auth:** Firebase Phone Auth (OTP on Indian mobile number)
- **Billing:** Razorpay Flutter SDK — in-app subscription purchase
- **Target:** Android only (API 26+). iOS deferred.
- **Play Store:** Separate listing from lumin-app (crypto). App name: "Lumin India" or owner-confirmed name.

---

## Signal Delivery Flow (understand this before touching any signal screen)

```
Engine emits signal
      ↓
FCM push notification → subscriber's phone
      ↓
User taps notification OR opens app
      ↓
App calls GET /api/india/signals (bearer token auth)
      ↓
Signal list screen renders signal cards
      ↓
User taps signal card → Signal detail screen
      ↓
(Phase 2) User's auto-trade setting determines if position is already open
```

FCM is the doorbell. The REST API is the source of truth. Never cache signal content locally beyond the current session — always re-fetch on app open.

---

## Screen Map

| Screen | Route | Purpose |
|---|---|---|
| Splash | `/` | Firebase init, auth check, route guard |
| Phone Auth | `/auth/phone` | Indian mobile OTP login |
| OTP Verify | `/auth/otp` | Verify 6-digit OTP |
| Home / Signal Feed | `/home` | Live signal list, session status bar |
| Signal Detail | `/signal/:id` | Full signal card: entry, SL, TP1, confidence, evaluator, chart context |
| Auto-Trade Settings | `/settings/autotrade` | Enable/disable, lot size, max positions (Phase 2 only, gated) |
| Subscription | `/subscription` | Plan picker, Razorpay payment, active plan display |
| Session Summary | `/session` | Today's session: signal count, win/loss if positions closed (Phase 2) |
| Profile | `/profile` | Phone number, plan, logout |
| (Phase 2) Positions | `/positions` | Open positions, PnL, manual close button |

---

## Key UI Rules

- **Signal cards are actionable, not decorative.** Show: direction (LONG/SHORT), symbol (NIFTY/BANKNIFTY), entry price, SL, TP1, confidence tier (A+/A/B), and time. Nothing more on the card.
- **Confidence tier color coding:** A+ = green, A = blue, B = amber. Never show raw score to subscriber — show tier only.
- **Session status bar** (always visible on Home): "Market Open 09:15–15:30 IST" or "Market Closed". Show today's signal count.
- **Phase 2 gating:** Auto-Trade Settings screen exists in the app from the start but shows a "Coming Soon — pending regulatory clearance" message until `AUTO_EXECUTION_ENABLED=true` is returned by the engine. Never hide the screen — just disable it with a clear message.
- **Subscription wall:** Signal detail is visible to all users. Signal entry price, SL, and TP1 are blurred/hidden for non-subscribers. Tap → paywall screen. Free users see signal exists but can't act on it.
- **No Telegram.** The app is the only delivery channel. There is no "join our Telegram" anywhere in the app.

---

## API Contract (what the app calls)

All requests include `Authorization: Bearer <firebase_id_token>` header.

```
GET  /api/india/signals          → list of signals (last 24h)
GET  /api/india/signals/:id      → single signal detail
GET  /api/india/session          → session status (open/closed, today's count)
GET  /api/india/pulse            → engine health check
GET  /api/india/positions        → open positions (Phase 2)
POST /api/india/settings         → update user auto-trade settings (Phase 2)
GET  /api/india/subscription     → current plan + expiry
POST /api/india/subscription/verify → verify Razorpay payment
POST /api/india/fcm-token        → register/update FCM device token
```

API base URL is runtime-configurable via `INDIA_API_BASE_URL` (set in `lib/config.dart`, overridable via a build flavor or `--dart-define`).

---

## FCM Notification Handling

- **Background tap:** navigate to Signal Detail screen for the signal_id in the notification payload
- **Foreground:** show in-app banner with signal summary; auto-navigate if user taps
- **Data payload must include:** `signal_id`, `symbol`, `direction`, `confidence_tier`
- **Never show raw price targets in the notification body** — just "NIFTY LONG signal — A+ confidence". Full detail in-app only (subscriber wall applies).

---

## Razorpay Billing

- Plans: ₹999/month (Tier B), ₹2499/month (Tier A+). Prices owner-confirmed before launch.
- Flow: user selects plan → Razorpay checkout → `payment_id` + `order_id` + `signature` returned → app calls POST `/api/india/subscription/verify` → engine validates with Razorpay server-side → subscription activated in SQLite
- Never trust the client-side Razorpay callback alone — always verify server-side.
- `RAZORPAY_KEY_ID` (public) lives in the app build config. `RAZORPAY_KEY_SECRET` lives in GitHub Actions secrets, never in the app.

---

## Auth Rules

- Firebase Phone Auth only. No email. No social login.
- OTP timeout: 60 seconds. Resend after timeout.
- Session token: Firebase ID token (1-hour TTL, auto-refreshed by FlutterFire).
- On 401 from API: refresh token → retry once → if still 401: log out and show login screen.
- Store Firebase ID token in memory only — never in SharedPreferences or local storage.

---

## Change-Management Protocol

Same as lumin-india-engine. Every change via PR. Never push to `main` directly.

Auto-merge: UI, navigation, non-billing, non-auth changes when CI green.

**Owner sign-off required:**
- Billing screen changes (Razorpay integration, plan prices, paywall logic)
- Auth flow changes
- Any screen that touches auto-trade settings (Phase 2)
- Play Store release

---

## Hard Limits

- Never show raw confidence score to subscribers — tier only (A+/A/B)
- Never make subscriber signals visible without auth verification
- Never store Firebase ID token on disk
- Never include `RAZORPAY_KEY_SECRET` in app bundle
- Never add "join Telegram" anywhere
- Never show auto-trade controls without Phase 2 engine activation
- Push to `main` directly — always via PR

---

## Commands

```bash
# Run on connected Android device
flutter run --flavor prod

# Build release APK
flutter build apk --release

# Build App Bundle (Play Store)
flutter build appbundle --release

# Tests
flutter test

# Analyze
flutter analyze

# Update deps
flutter pub get
```

**Testing on real device (mandatory before any signal-screen PR):**
Owner tests on their Android phone. Connect via USB or use wireless ADB. Run `flutter run` and walk through: login → home → signal card tap → detail screen. Report what you see, not what you expect.

---

## Conventions

- One feature per folder under `lib/features/` — `signals/`, `auth/`, `subscription/`, `settings/`, `session/`
- Riverpod providers in `lib/providers/`
- API client in `lib/api/india_api_client.dart`
- Config (base URLs, build flavors) in `lib/config.dart`
- Never use `BuildContext` across async gaps — check `mounted` before every post-await `context` use
- All strings user-visible in `lib/l10n/` — English only at launch, Hindi deferred
- IST display everywhere — convert UTC API timestamps to IST before rendering. Never display UTC to user.
