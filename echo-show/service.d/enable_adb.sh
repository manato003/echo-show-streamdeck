#!/system/bin/sh
# USB ADB only (Wi-Fi ADB intentionally disabled).
#
# 1. Fire OS init.cronos.rc runs "setprop service.adb.tcp.port 5555" on boot,
#    so adbd would also listen on Wi-Fi. Clear it and restart adbd once.
# 2. Fire OS resets "settings global adb_enabled" to 0 during boot, and
#    UsbDeviceManager then switches USB back to MTP. Keep re-asserting it.
until [ "$(getprop sys.boot_completed)" = "1" ]; do sleep 2; done
resetprop service.adb.tcp.port 0
stop adbd
start adbd
while true; do
    if [ "$(settings get global adb_enabled)" != "1" ]; then
        settings put global adb_enabled 1
    fi
    sleep 10
done
