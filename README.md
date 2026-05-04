# CalmPulse BP (Garmin Connect IQ MVP)

CalmPulse BP adalah aplikasi Garmin watch-only untuk membantu pengguna hipertensi muda melakukan intervensi mikro (pause + breathing) saat sinyal stres meningkat.

## Target release
- Device target: **Forerunner 55 (`fr55`)**
- Scope v1: mood-only reflection (`lebih_tenang`, `masih_tegang`, `lewati`)
- Positioning: self-awareness support, **bukan alat diagnosis/darurat**

## MVP flow
- First run: disclaimer + baseline heart-rate setup
- Idle monitoring: trigger rule (HR di atas baseline + inactivity + cooldown)
- Intervention: haptic nudge + 60 detik guided breathing
- Reflection: mood logging (tanpa input BP numerik di v1)
- Summary: trigger count, completion count, calming rate

## Build prerequisites
1. Install Connect IQ SDK.
2. Set environment variable `CIQ_SDK_HOME` ke path SDK (contoh: `/Users/<user>/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-*/`).
3. Generate/set developer key path di `CIQ_DEV_KEY`.
4. Open folder ini di VS Code.

## Build & run (VS Code tasks)
- Jalankan task `CIQ: Build FR55` untuk compile `.prg`.
- Jalankan task `CIQ: Run Simulator FR55` untuk simulasi.
- Artifact output: `bin/CalmPulseBP-fr55.prg`.

## Manual CLI (opsional)
```bash
$CIQ_SDK_HOME/bin/monkeyc -f manifest.xml -o bin/CalmPulseBP-fr55.prg -y $CIQ_DEV_KEY -d fr55 -w
$CIQ_SDK_HOME/bin/connectiq -d fr55 bin/CalmPulseBP-fr55.prg
```

## Safety statement
Aplikasi ini **bukan alat diagnosis** dan **bukan layanan darurat**. Gunakan sebagai pendamping self-awareness dan konsultasikan gejala persisten ke tenaga medis profesional.

## v1 limitation / v1.1 next
- v1 belum mengaktifkan input BP numerik manual.
- v1.1 akan menambahkan flow input sistolik/diastolik yang ringkas dan aman digunakan via tombol watch.
