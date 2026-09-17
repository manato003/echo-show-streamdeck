#!/system/bin/sh
# Enable USB ADB properties early in boot (systemless - survives OTA as long as
# Magisk is patched into the current boot image).
resetprop -n ro.debuggable 1
resetprop -n ro.adb.secure 0
resetprop persist.service.adb.enable 1
resetprop persist.service.debuggable 1
resetprop persist.sys.usb.config adb
