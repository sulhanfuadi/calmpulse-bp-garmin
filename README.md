# CalmPulse BP (Garmin Connect IQ)

CalmPulse BP adalah aplikasi watch-only untuk membantu pengguna melakukan jeda napas terarah saat sinyal stres meningkat.

## Production contract (MVP)
- Device utama: `fr55`
- State kontrak: `Onboarding -> Idle -> Triggered -> BreathingActive -> ReflectionPending -> Summary`
- Input kontrak:
  - `START`: setuju/start/konfirmasi
  - `UP/DOWN`: pilihan refleksi
  - `BACK`: batal/kembali
- Data sesi:
  - `timestamp`, `trigger_reason`, `session_completed`, `mood_after`, `optional_bp`
- Scope medis: self-awareness support, **bukan diagnosis** dan **bukan layanan darurat**

## Build prerequisites
1. Install Connect IQ SDK.
2. Set `CIQ_SDK_HOME` ke path SDK.
3. Set `CIQ_DEV_KEY` ke developer key `.der`.

## Preflight check (wajib sebelum build lokal)
```bash
./scripts/verify-env.sh fr55
```

Script ini akan memvalidasi:
- `CIQ_SDK_HOME` dan `CIQ_DEV_KEY`
- binary `monkeyc` dan `connectiq`
- file key `.der`
- deklarasi device `fr55` di `manifest.xml`

## Build local
```bash
$CIQ_SDK_HOME/bin/monkeyc \
  -f manifest.xml \
  -o bin/CalmPulseBP-fr55.prg \
  -y "$CIQ_DEV_KEY" \
  -d fr55 \
  -w
```

## Run simulator (opsional jika tersedia)
```bash
$CIQ_SDK_HOME/bin/connectiq -d fr55 bin/CalmPulseBP-fr55.prg
```

## Runtime hardening yang aktif
- Trigger gate aman: HR invalid/null di-skip tanpa crash.
- Storage fallback aman: read/write gagal tidak menghentikan app.
- Timer lifecycle aman: no double-start, no orphan timer saat state berubah.
- Daily metrics auto-reset berdasarkan tanggal lokal.
- UI memakai snapshot tunggal dari app state (read-only pada view).

## Known limitations
- Belum ada input BP numerik manual (tetap `optional_bp = null`).
- Validasi end-to-end simulator tergantung stabilitas simulator lokal.

## Manual QA checklist (tanpa simulator)
Lihat: `docs/QA_CHECKLIST.md`

## Troubleshooting build
- Jalankan `./scripts/verify-env.sh fr55` untuk diagnosa cepat.
- Error key signing: pastikan `CIQ_DEV_KEY` valid dan format `.der`.
- SDK tidak ditemukan: cek `echo $CIQ_SDK_HOME`.
- Product mismatch: gunakan target `-d fr55` sesuai manifest.

## Status update (May 2026)
- Build lokal sementara belum dijalankan karena kendala SDK environment di mesin pengembang.
- Kondisi ini tidak mengubah progres arsitektur/logic aplikasi yang sudah disempurnakan.
- Untuk menjaga momentum delivery, pengembangan aktif sementara dilanjutkan di jalur Apple Watch.

## Repository links
- Garmin: https://github.com/sulhanfuadi/calmpulse-bp-garmin
- Apple Watch: https://github.com/sulhanfuadi/calmpulse-bp-apple
