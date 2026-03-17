#!/system/bin/sh
# audio_tweaks.sh - Shared logic for applying audio profiles

apply_audio_profile() {
    local m="$1"
    
    # 1. CORE SYSTEM AUDIO OVERRIDES (Extreme Cleanup)
    # Force high priority for audio HAL
    resetprop -n persist.audio.hal.priority 1
    # Disable MIUI audio limitation
    resetprop -n audio.safevolume.force false
    resetprop -n ro.config.media_vol_steps 30
    # Enable Ultra HQ Resampler for all
    resetprop -n persist.af.resampler.quality 7
    # MTK Audio Engine Tuning
    resetprop -n persist.vendor.audio.aal.enabled 0
    resetprop -n persist.vendor.audio.clear.motion 1
    
    case "$m" in
        normal)
            # Balanced - Smooth & Clean
            resetprop -n ro.audio.buffer_ms 20
            resetprop -n vendor.audio.music.volume.gain 14
            resetprop -n persist.vendor.audio.besloudness.enabled 0
            resetprop -n persist.audio.dirac.speaker 1
            ;;
        bass)
            # EXTREME BASS - Deep & Punchy
            resetprop -n ro.audio.buffer_ms 24
            resetprop -n vendor.audio.music.volume.gain 22
            resetprop -n persist.vendor.audio.besloudness.enabled 1
            resetprop -n persist.vendor.audio.besloudness.type 1
            resetprop -n persist.vendor.audio.musicplus.enabled 1
            resetprop -n persist.audio.dirac.speaker 1
            # MTK Specific Bass Boost
            resetprop -n ro.vendor.audio.soundfx.type dirac
            resetprop -n vendor.audio.speaker.prot.enable true
            ;;
        gaming)
            # ZERO LATENCY - Sharp & Responsive
            resetprop -n ro.audio.buffer_ms 8
            resetprop -n vendor.audio.music.volume.gain 15
            resetprop -n persist.af.resampler.quality 3
            resetprop -n persist.audio.dirac.speaker 0
            # Disable non-essential effects for 0 delay
            resetprop -n persist.vendor.audio.besloudness.enabled 0
            resetprop -n persist.vendor.audio.double.mic.config 0
            # Faster audio path
            resetprop -n persist.vendor.audio.gaming.mode 1
            # Disable MTK dynamic volume to save CPU/Latency
            resetprop -n persist.vendor.audio.vow.dynamic.vol 0
            ;;
        hifi)
            # VIRTUAL HI-RES - 24bit/192kHz focus
            resetprop -n ro.audio.buffer_ms 40
            resetprop -n persist.af.resampler.quality 7
            resetprop -n persist.vendor.audio.hifi.enable 1
            resetprop -n ro.vendor.audio.hifi true
            resetprop -n persist.vendor.audio.srate.48000 false
            # Enable 24-bit PCM Offload
            resetprop -n audio.offload.pcm.24bit.enable true
            resetprop -n audio.offload.pcm.16bit.enable true
            resetprop -n persist.vendor.audio.pcm.192k.supported true
            # MTK Crystal Sound
            resetprop -n ro.mtk_audio_alac_support 1
            resetprop -n ro.audio.pcm.dynamic.processing true
            ;;
        cinema)
            # 360 SURROUND - Immersive Stage
            resetprop -n ro.audio.buffer_ms 32
            resetprop -n vendor.audio.music.volume.gain 18
            resetprop -n persist.vendor.audio.besloudness.enabled 1
            resetprop -n persist.audio.dirac.speaker 1
            resetprop -n ro.vendor.audio.soundfx.usb true
            # Wide stage properties
            resetprop -n persist.vendor.audio.surround.enable 1
            resetprop -n ro.audio.pcm.dynamic.processing true
            ;;
    esac
    
    # Refresh Audio Services (Force properties to take effect)
    killall -9 audioserver 2>/dev/null
    killall -9 android.hardware.audio@2.0-service 2>/dev/null
    killall -9 vendor.audio-hal-2-0 2>/dev/null
}
