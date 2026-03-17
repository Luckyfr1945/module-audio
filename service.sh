#!/system/bin/sh
# service.sh - KYY Audio Pro v2.0 (Selene MTK)
# Dijalankan saat boot oleh Magisk/KSU
# Baca mode dari config dan apply ke hardware audio

MODDIR="${0%/*}"
MODULE_DIR="/data/adb/modules/kyy_audio_selene"
MODE_FILE="$MODULE_DIR/audio_mode"
LOG_FILE="$MODULE_DIR/last_boot.log"

# Tunggu system & audio HAL benar-benar siap
# (audioserver butuh waktu start setelah boot)
sleep 15

# Baca mode yang disimpan, default "normal"
if [ -f "$MODE_FILE" ]; then
    MODE=$(cat "$MODE_FILE" | tr -d '[:space:]')
else
    MODE="normal"
    mkdir -p "$MODULE_DIR"
    echo "normal" > "$MODE_FILE"
fi

# Sourced shared tweaks
. $MODDIR/common/audio_tweaks.sh

# Logging
echo "[$(date)] Boot apply mode: $MODE" > "$LOG_FILE"

# Apply mode
apply_audio_profile "$MODE"

# Restart audioserver supaya property benar-benar ke-apply oleh HAL
killall audioserver 2>/dev/null
sleep 1
setprop ctl.restart audioserver 2>/dev/null
killall android.hardware.audio.service 2>/dev/null

echo "[$(date)] Mode $MODE applied successfully" >> "$LOG_FILE"
