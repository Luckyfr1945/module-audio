#!/system/bin/sh

apply_audio_profile() {
    local m="$1"
    
    resetprop audio.safevolume.force false
    resetprop persist.vendor.audio.aal.enabled 0
    resetprop persist.vendor.audio.effect.msbc 0
    resetprop persist.vendor.audio.tfa.fadein 0

    resetprop ro.config.media_vol_steps 30
    resetprop persist.audio.hal.priority 1
    resetprop persist.vendor.audio.clear.motion 1

    resetprop audio.offload.disable 0
    resetprop audio.deep_buffer.media 1
    resetprop audio.sys.noisy.broadcast.delay 0

    resetprop vendor.af.resampler.quality 4
    resetprop persist.af.resampler.quality 4
    resetprop persist.vendor.audio.hifi.enable 0
    resetprop ro.vendor.audio.hifi false
    resetprop persist.vendor.audio.srate.48000 true
    resetprop audio.offload.pcm.24bit.enable false
    resetprop persist.vendor.audio.pcm.192k.supported false

    case "$m" in
        normal)
            resetprop ro.audio.buffer_ms 20
            resetprop vendor.audio.music.volume.gain 14
            resetprop vendor.audio.sys.volume.gain 12
            resetprop persist.audio.dirac.speaker 1
            resetprop persist.vendor.audio.besloudness.enabled 0
            resetprop persist.vendor.audio.musicplus.enabled 0
            resetprop persist.vendor.audio.gaming.mode 0
            resetprop persist.vendor.audio.surround.enable 0
            ;;
        bass)
            resetprop ro.audio.buffer_ms 24
            resetprop vendor.audio.music.volume.gain 22
            resetprop vendor.audio.sys.volume.gain 18
            resetprop persist.vendor.audio.besloudness.enabled 1
            resetprop persist.vendor.audio.besloudness.type 1
            resetprop persist.vendor.audio.musicplus.enabled 1
            resetprop persist.audio.dirac.speaker 1
            resetprop persist.vendor.audio.bes.loudness.mode 1
            ;;
        gaming)
            resetprop ro.audio.buffer_ms 8
            resetprop vendor.audio.music.volume.gain 15
            resetprop vendor.audio.sys.volume.gain 12
            resetprop persist.af.resampler.quality 2
            resetprop vendor.af.resampler.quality 2
            resetprop persist.audio.dirac.speaker 0
            resetprop persist.vendor.audio.besloudness.enabled 0
            resetprop persist.vendor.audio.musicplus.enabled 0
            resetprop persist.vendor.audio.gaming.mode 1
            resetprop audio.deep_buffer.media 0
            resetprop persist.vendor.audio.vow.dynamic.vol 0
            ;;
        hifi)
            resetprop ro.audio.buffer_ms 40
            resetprop persist.af.resampler.quality 5
            resetprop vendor.af.resampler.quality 5
            resetprop vendor.audio.music.volume.gain 16
            resetprop persist.vendor.audio.hifi.enable 1
            resetprop ro.vendor.audio.hifi true
            resetprop persist.vendor.audio.hp.hifi 1
            resetprop audio.offload.pcm.24bit.enable true
            resetprop persist.vendor.audio.srate.48000 false
            resetprop persist.vendor.audio.pcm.192k.supported true
            ;;
        cinema)
            resetprop ro.audio.buffer_ms 32
            resetprop vendor.audio.music.volume.gain 16
            resetprop vendor.audio.sys.volume.gain 14
            resetprop persist.vendor.audio.besloudness.enabled 1
            resetprop persist.vendor.audio.besloudness.type 0
            resetprop persist.audio.dirac.speaker 1
            resetprop persist.vendor.audio.surround.enable 1
            resetprop audio.deep_buffer.media 1
            ;;
    esac

    setprop ctl.restart audioserver 2>/dev/null
    sleep 1
    pgrep -x audioserver > /dev/null || start audioserver 2>/dev/null
    pkill -f "vendor.audio-hal" 2>/dev/null
}
