#!/system/bin/sh
# action.sh - AudSel Backend v3.2
# Handles APK requests: get/set audio mode + real-time stats

MODULE_DIR="/data/adb/modules/kyy_audio_selene"
MODE_FILE="$MODULE_DIR/audio_mode"

ACTION="$1"
MODE="$2"

# =========================================================
# DEVICE DETECTION
# =========================================================
get_device() {
    # Source 1: AudioManager Device Broker — most accurate routing state
    local routing
    routing=$(/system/bin/dumpsys audio 2>/dev/null \
        | grep -A 5 "mDeviceBroker:" \
        | grep -m 1 "mDevice=" \
        | tr '[:upper:]' '[:lower:]')

    # Source 2: Wired headset via kernel switch node (most reliable for IEM)
    local h2w=0
    [ -f /sys/class/switch/h2w/state ] && h2w=$(cat /sys/class/switch/h2w/state 2>/dev/null)
    [ -f /sys/class/extcon/extcon0/state ] && {
        grep -qi "HEADPHONES=1\|HEADSET=1" /sys/class/extcon/extcon0/state 2>/dev/null && h2w=1
    }

    # Priority 1: Wired headset / IEM
    if [ "$h2w" != "0" ] && [ -n "$h2w" ]; then
        echo "Headset / IEM"
        return
    fi
    if echo "$routing" | grep -qE "headset|headphone|wired_headset"; then
        echo "Headset / IEM"
        return
    fi

    # Priority 2: Bluetooth — ONLY if audio is truly routed via BT
    if echo "$routing" | grep -qE "bluetooth_a2dp|a2dp_speaker|ble_headset|sco_headset"; then
        local bt_name=""
        # Most reliable source: A2DP connected device
        bt_name=$(/system/bin/dumpsys bluetooth_manager 2>/dev/null \
            | awk '/mBondedDevices/{found=1} found && /name=/{print; exit}' \
            | cut -d'=' -f2 | tr -d '\r\n "' | sed 's/,.*//')

        # Fallback: check audio focus output
        if [ -z "$bt_name" ] || [ "$bt_name" = "null" ] || [ "$bt_name" = "00" ]; then
            bt_name=$(/system/bin/dumpsys audio 2>/dev/null \
                | grep -i "address=" \
                | head -n 1 \
                | cut -d'=' -f2 \
                | tr -d ' \r\n')
        fi

        if [ -n "$bt_name" ] && [ "$bt_name" != "null" ]; then
            echo "TWS: $bt_name"
        else
            echo "Bluetooth Audio"
        fi
        return
    fi

    # Priority 3: USB Audio / DAC
    if echo "$routing" | grep -qE "usb_device|usb_headset"; then
        echo "USB Audio / DAC"
        return
    fi

    # Default: Built-in Speaker
    echo "Built-in Speaker"
}

# =========================================================
# SYSTEM INFO
# =========================================================
get_sysinfo() {
    local model cpu
    model=$(getprop ro.product.model 2>/dev/null)
    cpu=$(getprop ro.hardware 2>/dev/null)

    # Pretty-print CPU name
    case "$cpu" in
        *mt*|*MT*) cpu="MediaTek $(echo "$cpu" | tr 'a-z' 'A-Z')" ;;
        *qcom*)    cpu="Snapdragon" ;;
        *)         cpu="${cpu:-Unknown SoC}" ;;
    esac

    echo "${cpu} — ${model:-Android Device}"
}

# =========================================================
# REAL-TIME AUDIO STATS
# =========================================================
get_real_stats() {
    local hw_rate="" hw_buffer="" is_frames="false"
    local hifi="" g=""

    hifi=$(getprop persist.vendor.audio.hifi.enable 2>/dev/null)
    g=$(getprop persist.af.resampler.quality 2>/dev/null)

    # --- 1. ALSA kernel nodes (most accurate, only when playing) ---
    for pcm_dir in /proc/asound/card*/pcm*p/sub0; do
        [ -d "$pcm_dir" ] || continue
        grep -q "RUNNING" "$pcm_dir/status" 2>/dev/null || continue
        local hw_params
        hw_params=$(cat "$pcm_dir/hw_params" 2>/dev/null)
        hw_rate=$(echo "$hw_params" | awk '/^rate/{print $2; exit}')
        hw_buffer=$(echo "$hw_params" | awk '/^buffer_size/{print $2; exit}')
        [ -n "$hw_rate" ] && { is_frames="true"; break; }
    done

    # --- 2. AudioFlinger output thread (active or idle path) ---
    if [ -z "$hw_rate" ] || [ "$hw_rate" = "0" ]; then
        local flinger
        flinger=$(dumpsys media.audio_flinger 2>/dev/null)
        hw_rate=$(echo "$flinger" \
            | awk '/Output thread/{found=1} found && /sample rate:/{print $NF; exit}')
        hw_buffer=$(echo "$flinger" \
            | awk '/Output thread/{found=1} found && /frame count:/{print $NF; exit}')
        [ -n "$hw_rate" ] && is_frames="true"
    fi

    # --- 3. MTK HAL property fallback ---
    if [ -z "$hw_rate" ] || [ "$hw_rate" = "0" ]; then
        hw_rate=$(getprop vendor.audio.current.sample.rate 2>/dev/null)
        is_frames="false"
    fi

    # --- 4. Last resort: ro.audio.buffer_ms ---
    [ -z "$hw_rate" ] && hw_rate="48000"

    # --- Format sample rate ---
    local srt_val="48"
    if [ "$hw_rate" -gt 1000 ] 2>/dev/null; then
        srt_val=$((hw_rate / 1000))
    elif [ "$hw_rate" -gt 0 ] 2>/dev/null; then
        srt_val="$hw_rate"
    fi
    # HiFi override if idle
    if [ "$is_frames" = "false" ] && { [ "$hifi" = "1" ] || [ "$hifi" = "true" ]; }; then
        srt_val="192"
    fi

    # --- Format buffer ---
    local buf_val
    buf_val=$(getprop ro.audio.buffer_ms 2>/dev/null)
    if [ -n "$hw_buffer" ] && [ "$is_frames" = "true" ]; then
        buf_val="$hw_buffer"
    fi
    [ -z "$buf_val" ] && buf_val="-"

    # --- Format HiFi ---
    local hifi_status="OFF"
    { [ "$hifi" = "1" ] || [ "$hifi" = "true" ]; } && hifi_status="ON"

    printf '"srate":"%s","buffer":"%s","buffer_is_frames":%s,"gain":"%s","hifi":"%s"' \
        "$srt_val" "$buf_val" "$is_frames" "${g:-7}" "$hifi_status"
}

# =========================================================
# SOURCE TWEAKS
# =========================================================
# shellcheck source=common/audio_tweaks.sh
. "$MODULE_DIR/common/audio_tweaks.sh"

# =========================================================
# ROUTER
# =========================================================
case "$ACTION" in

    get_mode)
        CURRENT="normal"
        [ -f "$MODE_FILE" ] && CURRENT=$(tr -d '[:space:]' < "$MODE_FILE")
        DEV=$(get_device | tr -d '\r\n"')
        SYS=$(get_sysinfo | tr -d '\r\n"')
        STATS=$(get_real_stats)
        printf '{"success":true,"mode":"%s","device":"%s","sysinfo":"%s",%s}\n' \
            "$CURRENT" "$DEV" "$SYS" "$STATS"
        ;;

    set_mode)
        case "$MODE" in
            normal|bass|gaming|hifi|cinema) ;;
            *)
                printf '{"success":false,"error":"Unknown mode: %s"}\n' "$MODE"
                exit 1
                ;;
        esac

        mkdir -p "$MODULE_DIR"
        echo "$MODE" > "$MODE_FILE"

        # Apply synchronously first (APK waits for response)
        apply_audio_profile "$MODE" >/dev/null 2>&1

        DEV=$(get_device | tr -d '\r\n"')
        SYS=$(get_sysinfo | tr -d '\r\n"')
        STATS=$(get_real_stats)
        printf '{"success":true,"mode":"%s","device":"%s","sysinfo":"%s",%s}\n' \
            "$MODE" "$DEV" "$SYS" "$STATS"
        ;;

    *)
        printf '{"success":false,"error":"Invalid action"}\n'
        ;;
esac
