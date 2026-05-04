# CalmPulse BP (Garmin Connect IQ MVP)

CalmPulse BP adalah aplikasi Garmin watch-only untuk membantu pengguna hipertensi muda melakukan intervensi mikro (pause + breathing) saat sinyal stres meningkat.

## MVP flow
- First run: disclaimer + baseline heart-rate setup
- Idle monitoring: trigger rule (HR di atas baseline + inactivity + cooldown)
- Intervention: haptic nudge + 60 detik guided breathing
- Reflection: mood logging + optional manual blood pressure
- Summary: trigger count, completion count, calming rate

## Safety statement
Aplikasi ini **bukan alat diagnosis** dan **bukan layanan darurat**. Gunakan sebagai pendamping self-awareness dan konsultasikan gejala persisten ke tenaga medis profesional.

## Build notes
1. Install Connect IQ SDK + Monkey C extension.
2. Create/build project in VS Code with this folder.
3. Run on simulator/device that supports heart-rate APIs.
