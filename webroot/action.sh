#!/system/bin/sh

MODULE_DIR="/data/adb/modules/kyy_audio_selene"
MODE_FILE="$MODULE_DIR/audio_mode"

ACTION="$1"
MODE="$2"

get_device() {
    local routing
    routing=$(/system/bin/dumpsys audio 2>/dev/null | grep -A 5 "mDeviceBroker:" | grep -m 1 "mDevice=" | tr '[:upper:]' '[:lower:]')

    local h2w=0
    [ -f /sys/class/switch/h2w/state ] && h2w=$(cat /sys/class/switch/h2w/state 2>/dev/null)
    [ -f /sys/class/extcon/extcon0/state ] && {
        grep -qi "HEADPHONES=1\|HEADSET=1" /sys/class/extcon/extcon0/state 2>/dev/null && h2w=1
    }

    if [ "$h2w" != "0" ] && [ -n "$h2w" ]; then
        echo "Headset / IEM"
        return
    fi
    if echo "$routing" | grep -qE "headset|headphone|wired_headset"; then
        echo "Headset / IEM"
        return
    fi

    if echo "$routing" | grep -qE "bluetooth_a2dp|a2dp_speaker|ble_headset|sco_headset"; then
        local bt_name=""
        bt_name=$(/system/bin/dumpsys bluetooth_manager 2>/dev/null | awk '/mBondedDevices/{found=1} found && /name=/{print; exit}' | cut -d'=' -f2 | tr -d '\r\n "' | sed 's/,.*//')

        if [ -z "$bt_name" ] || [ "$bt_name" = "null" ]; then
            echo "Bluetooth Audio"
        else
            echo "TWS: $bt_name"
        fi
        return
    fi

    if echo "$routing" | grep -qE "usb_device|usb_headset"; then
        echo "USB Audio / DAC"
        return
    fi

    echo "Built-in Speaker"
}

get_sysinfo() {
    local model=$(getprop ro.product.model 2>/dev/null)
    local cpu=$(getprop ro.hardware 2>/dev/null)
    case "$cpu" in
        *mt*|*MT*) cpu="MediaTek" ;;
        *qcom*)    cpu="Snapdragon" ;;
        *)         cpu="Android" ;;
    esac
    echo "${cpu} — ${model}"
}

get_real_stats() {
    local hw_rate="" hw_buffer="" is_frames="false"
    local hifi=$(getprop persist.vendor.audio.hifi.enable 2>/dev/null)
    local g=$(getprop persist.af.resampler.quality 2>/dev/null)

    for pcm_dir in /proc/asound/card*/pcm*p/sub0; do
        [ -d "$pcm_dir" ] || continue
        grep -q "RUNNING" "$pcm_dir/status" 2>/dev/null || continue
        local hw_params=$(cat "$pcm_dir/hw_params" 2>/dev/null)
        hw_rate=$(echo "$hw_params" | awk '/^rate/{print $2; exit}')
        hw_buffer=$(echo "$hw_params" | awk '/^buffer_size/{print $2; exit}')
        [ -n "$hw_rate" ] && { is_frames="true"; break; }
    done

    if [ -z "$hw_rate" ]; then
        local flinger=$(dumpsys media.audio_flinger 2>/dev/null)
        hw_rate=$(echo "$flinger" | awk '/Output thread/{found=1} found && /sample rate:/{print $NF; exit}')
        hw_buffer=$(echo "$flinger" | awk '/Output thread/{found=1} found && /frame count:/{print $NF; exit}')
        [ -n "$hw_rate" ] && is_frames="true"
    fi

    [ -z "$hw_rate" ] && hw_rate="48000"
    local srt_val=$((hw_rate / 1000))
    
    [ -z "$hw_buffer" ] && hw_buffer=$(getprop ro.audio.buffer_ms 2>/dev/null)
    [ -z "$hw_buffer" ] && hw_buffer="-"

    local hifi_status="OFF"
    [ "$hifi" = "1" ] && hifi_status="ON"

    printf '"srate":"%s","buffer":"%s","buffer_is_frames":%s,"gain":"%s","hifi":"%s"' \
        "$srt_val" "$hw_buffer" "$is_frames" "${g:-4}" "$hifi_status"
}

if [ -d "$MODULE_DIR/common" ]; then
    . "$MODULE_DIR/common/audio_tweaks.sh"
else
    . "${0%/*}/../common/audio_tweaks.sh"
fi

case "$ACTION" in
    get_mode)
        CURRENT="normal"
        [ -f "$MODE_FILE" ] && CURRENT=$(tr -d '[:space:]' < "$MODE_FILE")
        DEV=$(get_device | tr -d '\r\n"')
        SYS=$(get_sysinfo | tr -d '\r\n"')
        STATS=$(get_real_stats)
        printf '{"success":true,"mode":"%s","device":"%s","sysinfo":"%s",%s}\n' "$CURRENT" "$DEV" "$SYS" "$STATS"
        ;;
    set_mode)
        case "$MODE" in
            normal|bass|gaming|hifi|cinema) ;;
            *) exit 1 ;;
        esac
        mkdir -p "$MODULE_DIR"
        echo "$MODE" > "$MODE_FILE"
        apply_audio_profile "$MODE" >/dev/null 2>&1
        DEV=$(get_device | tr -d '\r\n"')
        SYS=$(get_sysinfo | tr -d '\r\n"')
        STATS=$(get_real_stats)
        printf '{"success":true,"mode":"%s","device":"%s","sysinfo":"%s",%s}\n' "$MODE" "$DEV" "$SYS" "$STATS"
        ;;
    *) exit 1 ;;
esac
