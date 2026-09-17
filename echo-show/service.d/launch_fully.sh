#!/system/bin/sh
# Launch Fully Kiosk on the Companion emulator page once the Fire OS home screen is up.
# Fire OS ignores BOOT_COMPLETED for sideloaded apps, so this runs from Magisk instead.
# Replace <PC_IP> and <EMULATOR_ID> before deploying.
sleep 25
am start -a android.intent.action.VIEW -d 'http://<PC_IP>:8000/emulator/<EMULATOR_ID>' -n de.ozerov.fully/de.ozerov.fully.FullyActivity
