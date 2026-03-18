#!/system/bin/sh

MODDIR="${0%/*}"
MODULE_DIR="/data/adb/modules/kyy_audio_selene"
MODE_FILE="$MODULE_DIR/audio_mode"

while [ "$(getprop sys.boot_completed)" != "1" ]; do
    sleep 2
done

wait_audio() {
    local tries=0
    while [ $tries -lt 20 ]; do
        pgrep -x audioserver > /dev/null && return 0
        sleep 2
        tries=$((tries + 1))
    done
    return 1
}

wait_audio || exit 1
sleep 5

if [ -f "$MODE_FILE" ]; then
    MODE=$(tr -d '[:space:]' < "$MODE_FILE")
else
    MODE="normal"
    mkdir -p "$MODULE_DIR"
    echo "normal" > "$MODE_FILE"
fi

case "$MODE" in
    normal|bass|gaming|hifi|cinema) ;;
    *) MODE="normal" ;;
esac

. "$MODDIR/common/audio_tweaks.sh"
apply_audio_profile "$MODE"
