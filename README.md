# CalmPulse BP (Garmin Connect IQ)

CalmPulse BP is a Garmin watch-only app that helps users take short guided breathing pauses when stress signals increase.

## Production Contract (MVP)
- Primary target device: `fr55`
- State contract: `Onboarding -> Idle -> Triggered -> BreathingActive -> ReflectionPending -> Summary`
- Input contract:
  - `START`: acknowledge / start / confirm
  - `UP/DOWN`: reflection choices
  - `BACK`: cancel / return
- Session log contract:
  - `timestamp`, `trigger_reason`, `session_completed`, `mood_after`, `optional_bp`
- Medical scope: self-awareness support only, **not a diagnostic tool** and **not an emergency service**

## Build Prerequisites
1. Install the Garmin Connect IQ SDK.
2. Set `CIQ_SDK_HOME` to your SDK path.
3. Set `CIQ_DEV_KEY` to your developer key (`.der`).

## Preflight Check (Required Before Local Build)
Run:
```bash
./scripts/verify-env.sh fr55
```

This script validates:
- `CIQ_SDK_HOME` and `CIQ_DEV_KEY`
- `monkeyc` and `connectiq` binaries
- developer key file existence
- `fr55` target declaration in `manifest.xml`

## Local Build
```bash
$CIQ_SDK_HOME/bin/monkeyc \
  -f manifest.xml \
  -o bin/CalmPulseBP-fr55.prg \
  -y "$CIQ_DEV_KEY" \
  -d fr55 \
  -w
```

## Simulator Run (Optional)
```bash
$CIQ_SDK_HOME/bin/connectiq -d fr55 bin/CalmPulseBP-fr55.prg
```

## Runtime Hardening Included
- Safe trigger gating: invalid or missing HR samples are skipped without crashing.
- Safe storage fallback: storage read/write failures do not terminate the app.
- Safe timer lifecycle: no double-start and no orphan timers across state transitions.
- Daily metrics auto-reset based on local date.
- UI uses a single state snapshot contract (view is read-only).

## Known Limitations
- Manual BP numeric input is not included in this MVP (`optional_bp` remains `null`).
- End-to-end simulator validation depends on local simulator stability.

## Manual QA Checklist (Non-Simulator)
See: `docs/QA_CHECKLIST.md`

## Build Troubleshooting
- Run `./scripts/verify-env.sh fr55` for fast diagnostics.
- Signing key errors: confirm `CIQ_DEV_KEY` points to a valid `.der` key.
- SDK not found: verify with `echo $CIQ_SDK_HOME`.
- Product mismatch: use `-d fr55` to match `manifest.xml`.

## Status Update (May 2026)
- Local build is currently blocked by SDK environment issues on the developer machine.
- This does not change the app architecture and logic improvements already completed.
- To maintain delivery momentum, active development is currently continuing on the Apple Watch track.

## Repository Links
- Garmin: https://github.com/sulhanfuadi/calmpulse-bp-garmin
- Apple Watch: https://github.com/sulhanfuadi/calmpulse-bp-apple
