# Lumin India

NSE F&O intraday signals — subscriber Android app (Flutter).

Companion repos: [`Lumina-india-engine`](https://github.com/mkmk749278/Lumina-india-engine) (signal engine + API), `Lumin-india-ops` (ops dashboard).

## Run (owner testing, Phase 1)

```bash
flutter pub get
flutter run \
  --dart-define=INDIA_API_BASE_URL=http://95.111.241.97 \
  --dart-define=INDIA_API_TOKEN=<owner API token>
```

The token is the engine's `API_STATIC_TOKEN`. Firebase Phone Auth replaces
it for subscribers once the Firebase project lands.

## Status

Foundation: signal feed + detail against the live engine API. Auth (Firebase
Phone OTP), FCM push, and Razorpay billing land next — see `CLAUDE.md` for
the full screen map and rules.
