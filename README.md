# AudSel Extreme (Redmi 10 Selene)
**Version: v3.3-EXTREME (Battery & Thermal Optimized)**

### Technical Overview
This module is specifically tuned for the **MT6768 (Helio G88)** chipset to maximize audio fidelity while maintaining optimal thermal efficiency and battery life. It overrides the default MTK audio drivers and Android audio HAL to provide real hardware/software audio profiles.

### Core Optimizations (v3.3)
- **Balanced Resampling**: Lowered `af.resampler.quality` from 7 (Overkill/Heat source) to 4 (High Fidelity / Efficiency).
- **Thermal Mitigation**: Disables unnecessary background DSP processing (BesLoudness/MusicPlus) by default to prevent audio IC overheating.
- **Smart HiFi**: High-resolution PCM (96k/24bit) is only context-switched in HiFi mode to save battery during regular playback.
- **Low-Latency Stack**: Gaming mode utilizes a simplified resampling pipeline (quality level 2) for minimum delay without the jitter of stock MTK processing.

### Profiles
- **Normal**: Perfectly flat 48kHz output. Low power consumption.
- **Bass Boost**: Enhanced low-end gain with Dirac spatialization.
- **Gaming**: Ultra-low buffer (8ms) + high-speed resampling.
- **Hi-Fi**: Forces PCM 24-bit/96kHz passthrough with high-quality offload.
- **Cinema**: Widened stereo stage + virtual surround upmix.

---
**Author: Luckyfr1945 x KYY**
