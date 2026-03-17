#!/system/bin/sh
# action.sh - APK Backend (V8 - Enhanced Detection & Tweaks)

MODULE_DIR="/data/adb/modules/kyy_audio_selene"
MODE_FILE="$MODULE_DIR/audio_mode"

ACTION="$1"
MODE="$2"

get_device() {
    # 1. Get exact active routing from Audio Manager (The OS Truth)
    local active_routing=$(/system/bin/dumpsys audio 2>/dev/null | grep -A 10 "mDeviceBroker:" | grep "mDevice=" | head -n 1 | tr '[:upper:]' '[:lower:]')
    
    # 2. Check for Wired Headset/IEM (High Priority)
    if echo "$active_routing" | grep -qE "headset|headphone|wired"; then
        echo "Headset / IEM"
        return
    elif [ -f /sys/class/switch/h2w/state ]; then
        if [ "$(cat /sys/class/switch/h2w/state 2>/dev/null)" != "0" ]; then
            echo "Headset / IEM"
            return
        fi
    fi

    # 3. Check for Bluetooth (Only if actually routed)
    if echo "$active_routing" | grep -qE "bluetooth|a2dp|ble|sco"; then
        local bt_name=""
        # Target only the truly ACTIVE bluetooth device name
        bt_name=$(/system/bin/dumpsys bluetooth_manager 2>/dev/null | grep -A 15 "Active devices" | grep "name=" | head -n 1 | cut -d'=' -f2 | tr -d '\r\n "' | sed 's/,.*//')
        
        if [ -z "$bt_name" ] || [ "$bt_name" = "null" ]; then
            # Second attempt via Audio Manager
            bt_name=$(/system/bin/dumpsys audio 2>/dev/null | grep -i "mBluetoothHeadsetDevice" | head -n 1 | cut -d',' -f1 | cut -d':' -f2 | tr -d ' ')
        fi

        if [ -n "$bt_name" ] && [ "$bt_name" != "null" ]; then 
            echo "TWS: $bt_name"
        else 
            echo "Bluetooth Audio"
        fi
        return
    fi

    # 4. Check for USB Audio
    if echo "$active_routing" | grep -q "usb"; then
        echo "USB Audio / DAC"
        return
    fi

    # 5. Default to Speaker
    echo "Built-in Speaker"
}

get_sysinfo() {
    local model=$(getprop ro.product.model)
    local cpu=$(getprop ro.hardware)
    # Merapihkan nama CPU biar profesional
    if echo "$cpu" | grep -qi 'mt'; then
        cpu=$(echo "$cpu" | tr '[:lower:]' '[:upper:]')
        cpu="MediaTek $cpu"
    elif echo "$cpu" | grep -qi 'qcom'; then
        cpu="Snapdragon"
    fi
    
    [ -z "$model" ] && model="Android Device"
    [ -z "$cpu" ] && cpu="Unknown SOC"
    
    echo "$cpu — $model"
}

get_real_stats() {
    local hw_rate=""
    local hw_buffer=""
    local hifi=$(getprop persist.vendor.audio.hifi.enable)
    
    # Check Hardware ALSA Nodes (Direct Kernel Data)
    for pcm in /proc/asound/card*/pcm*p; do
        if [ -d "$pcm/sub0" ] && grep -q "RUNNING" "$pcm/sub0/status" 2>/dev/null; then
            local hw_params=$(cat "$pcm/sub0/hw_params" 2>/dev/null)
            hw_rate=$(echo "$hw_params" | grep "rate" | awk '{print $2}')
            hw_buffer=$(echo "$hw_params" | grep "buffer_size" | awk '{print $2}')
            [ -n "$hw_rate" ] && break
        fi
    done

    # Fallback to AudioFlinger Thread Parsing (HAL Truth)
    if [ -z "$hw_rate" ] || [ "$hw_rate" = "0" ]; then
        local flinger=$(dumpsys media.audio_flinger 2>/dev/null)
        # Target the Sample Rate from the active MIXER thread
        hw_rate=$(echo "$flinger" | grep -A 30 "Output thread" | grep -A 5 "Thread Type:" | grep -m 1 "sample rate:" | awk '{print $NF}' | head -n 1)
        hw_buffer=$(echo "$flinger" | grep -A 30 "Output thread" | grep -A 5 "Thread Count:" | grep -m 1 "frame count:" | awk '{print $NF}' | head -n 1)
    fi

    # Final Fallback to MTK Engine Props if audio is totally idle
    if [ -z "$hw_rate" ]; then
        hw_rate=$(getprop vendor.audio.current.sample.rate)
        [ -z "$hw_rate" ] && hw_rate="48000"
    fi

    # Format Sample Rate
    local srt_val="48"
    if [ -n "$hw_rate" ] && [ "$hw_rate" -gt 0 ] 2>/dev/null; then
        if [ "$hw_rate" -gt 1000 ]; then
            srt_val=$(($hw_rate / 1000))
        else
            srt_val="$hw_rate"
        fi
    elif [ "$hifi" = "1" ] || [ "$hifi" = "true" ]; then
        srt_val="192"
    fi

    # Format Buffer
    local b=$(getprop ro.audio.buffer_ms) # Original 'b' variable
    local buf_val="$b"
    if [ -n "$hw_buffer" ]; then
        # Convert frames to ms approximately (frames / rate * 1000)
        # But for UI, frames might be more accurate or just use the target ms
        buf_val="$hw_buffer"
        local is_frames=true
    else
        [ -z "$buf_val" ] && buf_val="-"
        local is_frames=false
    fi

    # Format Hi-Fi
    local hifi_status="OFF"
    [ "$hifi" = "1" ] || [ "$hifi" = "true" ] && hifi_status="ON"
    
    printf '"buffer":"%s","buffer_is_frames":%s,"gain":"%s","hifi":"%s","srate":"%s"' "$buf_val" "${is_frames:-false}" "$g" "$hifi_status" "$srt_val"
}

# Sourced shared tweaks
. $MODULE_DIR/common/audio_tweaks.sh

set_props() {
    apply_audio_profile "$1"
}

# =========================================================
# ROUTER & OUTPUT
# =========================================================
case "$ACTION" in
    get_mode)
        if [ -f "$MODE_FILE" ]; then
            CURRENT=$(cat "$MODE_FILE" | tr -d '[:space:]')
        else
            CURRENT="normal"
        fi
        
        STATS=$(get_real_stats)
        DEV=$(get_device | tr -d '\r\n"')
        SYS=$(get_sysinfo | tr -d '\r\n"')
        
        printf '{"success":true,"mode":"%s","device":"%s","sysinfo":"%s",%s}\n' "$CURRENT" "$DEV" "$SYS" "$STATS"
        ;;
        
    set_mode)
        if echo "normal bass gaming hifi cinema" | grep -qw "$MODE"; then
            mkdir -p "$MODULE_DIR"
            echo "$MODE" > "$MODE_FILE"
            
            set_props "$MODE" >/dev/null 2>&1
            STATS=$(get_real_stats)
            DEV=$(get_device | tr -d '\r\n"')
            SYS=$(get_sysinfo | tr -d '\r\n"')
            
            printf '{"success":true,"mode":"%s","device":"%s","sysinfo":"%s",%s}\n' "$MODE" "$DEV" "$SYS" "$STATS"
            
            # Restart system sound lebih aggresif
            (
                sleep 0.2
                killall audioserver >/dev/null 2>&1
                setprop ctl.restart audioserver >/dev/null 2>&1
                killall android.hardware.audio.service >/dev/null 2>&1
            ) >/dev/null 2>&1 &
        else
            printf '{"success":false,"error":"Mode invalid"}\n'
        fi
        ;;
    *)
        printf '{"success":false,"error":"Action kosong"}\n'
        ;;
esac
