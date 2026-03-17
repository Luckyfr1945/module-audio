# KYY Audio Pro (Redmi 10 Selene)

![Version](https://img.shields.io/badge/Version-v3.2_Extreme-blue.svg)
![Platform](https://img.shields.io/badge/Platform-MediaTek_MT6768-orange.svg)
![Requirement](https://img.shields.io/badge/Requirement-Magisk%20/%20KSU-red.svg)

KYY Audio Pro adalah Magisk Module premium yang dirancang khusus untuk mengoptimalkan output audio pada perangkat **Redmi 10 (Selene)** dengan chipset MediaTek MT6768. Modul ini sekarang terintegrasi sepenuhnya dengan aplikasi Android native untuk kontrol mode audio secara real-time.

## ✨ Fitur Utama
- **Extreme Audio Tweaks**: Optimasi pada core MTK BesLoudness dan Dynamic Quality Enrichment.
- **Native APK Integration**: Tidak lagi menggunakan WebUI yang lambat. Gunakan aplikasi KYY Audio Pro untuk mengubah mode.
- **High-Res Audio**: Dukungan 24-bit/192kHz PCM Offload.
- **Ultra Low Latency**: Buffer tuning hingga 8ms untuk mode gaming.
- **Dynamic Device Detection**: Deteksi akurat untuk Speaker, IEM, TWS, dan USB DAC.

## 🎵 Mode Audio
1. **Normal**: Seimbang dan jernih untuk penggunaan sehari-hari.
2. **Bass Booster**: Dentuman bass yang dalam dan bertenaga (+22 Gain).
3. **Gaming**: Latensi nol dan suara yang tajam untuk kompetisi.
4. **Hi-Fi**: Kualitas audio tertinggi dengan resampler berkualitas tinggi.
5. **Cinema**: Stage surround yang luas untuk pengalaman menonton film.

## 🚀 Cara Instalasi
1. Download file `AudSel_Extreme_v3.2.zip` dari bagian [Releases](https://github.com/Luckyfr1945/module-audio/releases).
2. Instal melalui aplikasi **Magisk** atau **KernelSU**.
3. Reboot perangkat.
4. Instal aplikasi pendukung **AudSel APK** untuk mulai mengatur mode audio.

## ⚠️ Peringatan
Modul ini melakukan modifikasi pada properti sistem audio tingkat rendah. Gunakan dengan risiko sendiri.

## 📋 Changelog
### v3.2 Extreme (Latest)
- Tulis ulang total `audio_tweaks.sh` dengan global baseline cleanup per mode
- Tambah MTK sub-bass targeting (`bes.loudness.mode`)
- Tambah 24-bit headphone HiFi path (`persist.vendor.audio.hp.hifi`)
- Gaming: paksa FastMixer path & nonaktifkan deep buffer
- Restart audio HAL lebih aman via `setprop ctl.restart` + polling
- `service.sh`: polling audioserver bukan fixed sleep
- Validasi mode saat boot, cegah status korup
- Tambah `update.json` untuk OTA update via Magisk Manager
- Deteksi IEM via extcon + BT A2DP lebih akurat

### v3.1 Extreme
- ALSA + AudioFlinger real-time stats, 30-step volume, MTK BesLoudness

### v3.0
- Integrasi APK, hapus WebUI

---
**Author**: Luckyfr1945 x KYY  
**Support**: Redmi 10 (Selene) · MT6768

