#!/system/bin/sh
# audio_tweaks.sh - AudSel Extreme v3.2
# MTK-Targeted Audio Profile Engine for Selene (MT6768)
# =========================================================

apply_audio_profile() {
    local m="$1"
    
    # -------------------------------------------------------
    # GLOBAL BASELINE - Apply to ALL modes
    # Clears MIUI/Stock bloat and sets clean foundation
    # -------------------------------------------------------
    
    # 1. Disable ALL MIUI audio limiters/compressors
    resetprop audio.safevolume.force false
    resetprop persist.vendor.audio.aal.enabled 0        # Adaptive Audio Limiter OFF
    resetprop persist.vendor.audio.effect.msbc 0        # Disable mSBC (phone calls only)
    resetprop persist.vendor.audio.tfa.fadein 0         # DRC Fade OFF

    # 2. Volume & Headroom control
    resetprop ro.config.media_vol_steps 30              # 30-step precision volume
    resetprop persist.audio.hal.priority 1              # HAL audio priority = HIGH
    resetprop persist.vendor.audio.clear.motion 1       # ClearMotion audio stable

    # 3. Audio offload clean
    resetprop audio.offload.disable 0
    resetprop audio.deep_buffer.media 1
    resetprop audio.sys.noisy.broadcast.delay 0

    # 4. MTK signal processing cleanup
    resetprop vendor.af.resampler.quality 7             # Resampler = best quality
    resetprop persist.af.resampler.quality 7
    resetprop persist.vendor.audio.hifi.enable 0        # RESET first (overridden per mode)
    resetprop ro.vendor.audio.hifi false
    resetprop persist.vendor.audio.srate.48000 true     # RESET to 48kHz baseline
    resetprop audio.offload.pcm.24bit.enable false
    resetprop persist.vendor.audio.pcm.192k.supported false

    # -------------------------------------------------------
    # PER-MODE PROFILE
    # -------------------------------------------------------
    case "$m" in

        normal)
            # ── BALANCED ──────────────────────────────────
            # Flat EQ, minimal processing, natural sound
            resetprop ro.audio.buffer_ms 20
            resetprop vendor.audio.music.volume.gain 14
            resetprop vendor.audio.sys.volume.gain 12
            resetprop persist.audio.dirac.speaker 1     # Dirac spatial ON
            resetprop persist.vendor.audio.besloudness.enabled 0
            resetprop persist.vendor.audio.musicplus.enabled 0
            resetprop persist.vendor.audio.gaming.mode 0
            resetprop persist.vendor.audio.surround.enable 0
            ;;

        bass)
            # ── EXTREME BASS ─────────────────────────────
            # Aggressive low-frequency extension via BesLoudness
            resetprop ro.audio.buffer_ms 24
            resetprop vendor.audio.music.volume.gain 22  # +22 headroom for punch
            resetprop vendor.audio.sys.volume.gain 18
            resetprop persist.vendor.audio.besloudness.enabled 1
            resetprop persist.vendor.audio.besloudness.type 1
            resetprop persist.vendor.audio.musicplus.enabled 1
            resetprop persist.audio.dirac.speaker 1
            resetprop ro.vendor.audio.soundfx.type dirac
            resetprop vendor.audio.speaker.prot.enable true
            resetprop persist.vendor.audio.surround.enable 0
            resetprop persist.vendor.audio.gaming.mode 0
            # Sub-bass freq target (MTK BES)
            resetprop persist.vendor.audio.bes.loudness.mode 2
            ;;

        gaming)
            # ── ZERO LATENCY ─────────────────────────────
            # Minimal buffer, zero enhancement pipeline
            resetprop ro.audio.buffer_ms 8              # 8ms = lowest latency
            resetprop vendor.audio.music.volume.gain 15
            resetprop vendor.audio.sys.volume.gain 14
            resetprop persist.af.resampler.quality 3    # Fastest resampler (not HQ)
            resetprop vendor.af.resampler.quality 3
            resetprop persist.audio.dirac.speaker 0     # Kill Dirac (latency source)
            resetprop persist.vendor.audio.besloudness.enabled 0
            resetprop persist.vendor.audio.musicplus.enabled 0
            resetprop persist.vendor.audio.double.mic.config 0
            resetprop persist.vendor.audio.gaming.mode 1  # MTK gaming mode ON
            resetprop persist.vendor.audio.vow.dynamic.vol 0
            resetprop persist.vendor.audio.surround.enable 0
            resetprop audio.deep_buffer.media 0         # Disable deep buffer = lower latency
            # Force FastMixer path
            resetprop persist.vendor.audio.fluence.voicecall false
            resetprop persist.vendor.audio.fluence.voicecomm false
            ;;

        hifi)
            # ── HI-RES / AUDIOPHILE ───────────────────────
            # 24-bit/192kHz headphone focus, maximum fidelity
            resetprop ro.audio.buffer_ms 40             # Larger buffer = less jitter
            resetprop persist.af.resampler.quality 7
            resetprop vendor.af.resampler.quality 7
            resetprop vendor.audio.music.volume.gain 15
            resetprop vendor.audio.sys.volume.gain 14
            resetprop persist.vendor.audio.hifi.enable 1 # MTK Wired HiFi PATH ON
            resetprop ro.vendor.audio.hifi true
            resetprop persist.vendor.audio.srate.48000 false     # Allow >48kHz srate
            resetprop audio.offload.pcm.24bit.enable true
            resetprop audio.offload.pcm.16bit.enable true
            resetprop persist.vendor.audio.pcm.192k.supported true
            resetprop ro.mtk_audio_alac_support 1       # ALAC lossless decode
            resetprop ro.audio.pcm.dynamic.processing true
            resetprop persist.audio.dirac.speaker 0     # Bypass Dirac for pure signal
            resetprop persist.vendor.audio.besloudness.enabled 0
            resetprop persist.vendor.audio.gaming.mode 0
            resetprop audio.deep_buffer.media 1
            # 24bit headphone path
            resetprop persist.vendor.audio.hp.hifi 1
            ;;

        cinema)
            # ── VIRTUAL SURROUND ────────────────────────
            # Wide stereo stage + dynamic processing
            resetprop ro.audio.buffer_ms 32
            resetprop vendor.audio.music.volume.gain 18
            resetprop vendor.audio.sys.volume.gain 16
            resetprop persist.vendor.audio.besloudness.enabled 1
            resetprop persist.vendor.audio.besloudness.type 0   # Balanced loudness
            resetprop persist.audio.dirac.speaker 1
            resetprop ro.vendor.audio.soundfx.usb true
            resetprop persist.vendor.audio.surround.enable 1   # Surround upmix ON
            resetprop ro.audio.pcm.dynamic.processing true
            resetprop persist.vendor.audio.gaming.mode 0
            resetprop persist.vendor.audio.musicplus.enabled 1  # MusicPlus widening
            resetprop audio.deep_buffer.media 1
            ;;
    esac

    # -------------------------------------------------------
    # FINAL: Restart Audio HAL to flush all properties
    # Use safe method: setprop trigger instead of killall
    # -------------------------------------------------------
    # 1. Graceful restart first
    setprop ctl.restart audioserver 2>/dev/null

    # 2. Hard kill only if needed (gives 1s for graceful)
    sleep 1
    pgrep -x audioserver > /dev/null || {
        start audioserver 2>/dev/null
    }

    # 3. Kill old HAL service if lingering
    pkill -f "vendor.audio-hal" 2>/dev/null
}
