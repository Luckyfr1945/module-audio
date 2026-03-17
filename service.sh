#!/system/bin/sh
# service.sh - AudSel Extreme v3.2
# Dijalankan saat boot oleh Magisk/KSU
# Menunggu system audio HAL siap lalu apply profil tersimpan

MODDIR="${0%/*}"
MODULE_DIR="/data/adb/modules/kyy_audio_selene"
MODE_FILE="$MODULE_DIR/audio_mode"
LOG_FILE="$MODULE_DIR/last_boot.log"

# ── Wait for audioserver to be fully ready ─────────────────
# Better approach: poll instead of fixed sleep
wait_audio() {
    local tries=0
    while [ $tries -lt 30 ]; do
        pgrep -x audioserver > /dev/null && return 0
        sleep 2
        tries=$((tries + 1))
    done
    return 1
}

# Wait up to 60s for audio HAL
wait_audio || {
    echo "[$(date)] audioserver never started, aborting." > "$LOG_FILE"
    exit 1
}

# Extra settle time after detection
sleep 5

# ── Read saved mode ────────────────────────────────────────
if [ -f "$MODE_FILE" ]; then
    MODE=$(tr -d '[:space:]' < "$MODE_FILE")
else
    MODE="normal"
    mkdir -p "$MODULE_DIR"
    echo "normal" > "$MODE_FILE"
fi

# Validate mode
case "$MODE" in
    normal|bass|gaming|hifi|cinema) ;;
    *) MODE="normal" ;;
esac

# ── Source shared tweaks ───────────────────────────────────
. "$MODDIR/common/audio_tweaks.sh"

# ── Logging ────────────────────────────────────────────────
mkdir -p "$MODULE_DIR"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Boot: applying mode = $MODE" > "$LOG_FILE"

# ── Apply ─────────────────────────────────────────────────
apply_audio_profile "$MODE"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Mode '$MODE' applied OK." >> "$LOG_FILE"
