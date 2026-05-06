# CalmPulse BP (Garmin Connect IQ)

CalmPulse BP is a Garmin watch-only app for guided micro-pauses when stress signals rise.

## MVP Contract
- **Primary device:** `fr55`
- **State flow:** `Onboarding -> Idle -> Triggered -> BreathingActive -> ReflectionPending -> Summary`
- **Input mapping:**
  - `START` = acknowledge / start / confirm
  - `UP/DOWN` = reflection choices
  - `BACK` = cancel / return
- **Session log fields:** `timestamp`, `trigger_reason`, `session_completed`, `mood_after`, `optional_bp`
- **Safety scope:** self-awareness support only (**not diagnosis**, **not emergency care**)

## Local Setup
1. Install Garmin Connect IQ SDK.
2. Set `CIQ_SDK_HOME` to your SDK directory.
3. Set `CIQ_DEV_KEY` to your `.der` developer key.

## Environment Preflight
Run before local build:

```bash
./scripts/verify-env.sh fr55
```

Checks include:
- `CIQ_SDK_HOME` and `CIQ_DEV_KEY`
- `monkeyc` and `connectiq` binaries
- Developer key file existence
- `fr55` target declaration in `manifest.xml`

## Build & Run
**Build**
```bash
$CIQ_SDK_HOME/bin/monkeyc \
  -f manifest.xml \
  -o bin/CalmPulseBP-fr55.prg \
  -y "$CIQ_DEV_KEY" \
  -d fr55 \
  -w
```

**Simulator (optional)**
```bash
$CIQ_SDK_HOME/bin/connectiq -d fr55 bin/CalmPulseBP-fr55.prg
```

## Hardening Included
- Safe trigger gating for invalid/missing HR samples.
- Safe storage fallback on read/write errors.
- Safe timer lifecycle across state transitions.
- Daily metric reset based on local date.
- Single UI snapshot contract (view remains read-only).

## Known Limitations
- Manual BP numeric input is not in this MVP (`optional_bp` remains `null`).
- End-to-end simulator validation depends on local SDK/simulator health.

## Validation References
- Manual QA checklist: [`docs/QA_CHECKLIST.md`](docs/QA_CHECKLIST.md)
- Build troubleshooting guide:
  - Run [`./scripts/verify-env.sh fr55`](scripts/verify-env.sh) for quick diagnostics.
  - Confirm `CIQ_DEV_KEY` points to a valid `.der` key.
  - Verify SDK path with `echo $CIQ_SDK_HOME`.
  - Use `-d fr55` to match `manifest.xml`.

## Project Status (May 2026)
Local build is currently blocked by SDK environment issues on the current developer machine. This is an infrastructure blocker and does not change the architecture/runtime hardening already completed in this repository.

## Continuation Plan
Garmin readiness continues in parallel while SDK recovery is in progress. To keep delivery momentum, active implementation and validation continue on the Apple Watch track, then relevant learnings are folded back into Garmin execution.

## References
- Garmin repository: <https://github.com/sulhanfuadi/calmpulse-bp-garmin>
- Apple Watch repository: <https://github.com/sulhanfuadi/calmpulse-bp-apple>
