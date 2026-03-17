#!/system/bin/sh
# customize.sh - Dijalankan saat instalasi Magisk/KSU

SKIPUNZIP=0

ui_print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
ui_print "  KYY Audio Pro v2.0"
ui_print "  with APK Controller"
ui_print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
ui_print ""
ui_print "- Menginstal KYY Audio Pro..."
ui_print "- Mengecek hardware audio..."

# Deteksi Vendor (Qualcomm/MTK)
if [ "$(getprop ro.hardware)" == "qcom" ]; then
    ui_print "- [INFO] Perangkat Qualcomm terdeteksi"
else
    ui_print "- [INFO] Perangkat MediaTek terdeteksi"
fi

ui_print "- Mengatur permission..."
set_perm_recursive $MODPATH/system 0 0 0755 0644

# Setup APK Backend
ui_print "- Setting up APK backend..."
mkdir -p "$MODPATH/webroot"
mkdir -p "$MODPATH/common"
set_perm_recursive "$MODPATH/webroot" 0 0 0755 0644
set_perm_recursive "$MODPATH/common" 0 0 0755 0644
chmod 0755 "$MODPATH/webroot/action.sh" 2>/dev/null
chmod 0755 "$MODPATH/common/audio_tweaks.sh" 2>/dev/null

# Setup default audio mode
CONFIG_DIR="/data/adb/modules/kyy_audio_selene"
if [ ! -f "$CONFIG_DIR/audio_mode" ]; then
    mkdir -p "$CONFIG_DIR"
    echo "normal" > "$CONFIG_DIR/audio_mode"
    ui_print "- Mode audio default: Normal"
fi

ui_print ""
ui_print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
ui_print "  Mode Audio Tersedia:"
ui_print "  🎵 Normal  | 🔊 Bass Booster"
ui_print "  🎮 Gaming  | 🎧 Hi-Fi"
ui_print "  🎬 Cinema"
ui_print ""
ui_print "  Ubah mode via aplikasi KYY Audio Pro"
ui_print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
ui_print ""
ui_print "- Instalasi selesai! Silahkan reboot."
