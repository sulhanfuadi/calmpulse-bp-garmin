# QA Checklist (Non-Simulator Baseline)

## 1) Build Proof
- [ ] Compile target `fr55` sukses tanpa error.
- [ ] Artifact `bin/CalmPulseBP-fr55.prg` terbentuk.

## 2) State Machine Static Review
- [ ] Onboarding -> Idle hanya via `START`.
- [ ] Idle -> Triggered hanya saat trigger gate lolos.
- [ ] Triggered -> BreathingActive hanya via `START`.
- [ ] BreathingActive -> ReflectionPending via selesai timer atau `BACK`.
- [ ] ReflectionPending -> Summary via pilihan mood.
- [ ] Summary -> Idle via `BACK`.

## 3) Trigger Gate Review
- [ ] HR null/0/invalid tidak mentrigger.
- [ ] Inactivity belum memenuhi tidak mentrigger.
- [ ] Cooldown belum lewat tidak mentrigger.
- [ ] Cooldown lewat + HR tinggi + inactivity terpenuhi mentrigger.

## 4) Timer Lifecycle Review
- [ ] Monitor timer dimulai saat idle monitoring aktif.
- [ ] Monitor timer berhenti saat app stop.
- [ ] Breathing timer stop otomatis saat state bukan breathing.
- [ ] Tidak ada start timer ganda saat transisi berulang.

## 5) Storage & Recovery Review
- [ ] First run: disclaimer belum ack -> onboarding.
- [ ] Resume app: state recovery aman ke idle monitoring.
- [ ] Data korup/default fallback tidak crash.
- [ ] Metrics harian reset saat tanggal berubah.

## 6) Manual Scenario Script
- [ ] Happy path penuh: onboarding -> summary -> idle.
- [ ] Skip breathing: `BACK` saat breathing -> reflection -> summary.
- [ ] Reflection `lewati` tersimpan dan kembali normal.
- [ ] Forced stop saat breathing tidak meninggalkan timer aktif.
