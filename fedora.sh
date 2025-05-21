#!/bin/bash
set -euo pipefail

MODULE_NAME="90suspend-to-ram"
MODULE_DIR="/usr/lib/dracut/modules.d/$MODULE_NAME"

echo "[*] Creating Dracut module directory..."
sudo mkdir -p "$MODULE_DIR"

echo "[*] Writing suspend-to-ram.sh hook..."
cat <<'EOF' > /tmp/suspend-to-ram.sh
#!/bin/sh

echo 'Executing suspend-to-ram hook...'

FILE='/sys/class/rtc/rtc0/wakealarm'
EPOCH_TIME="$(date '+%s')"

# Reset RTC wakealarm
echo 0 > "$FILE" || reboot -f

# Set RTC wakealarm 2 seconds ahead
echo "$((EPOCH_TIME + 2))" > "$FILE" || reboot -f

# Suspend to RAM
echo mem > /sys/power/state || reboot -f
EOF

sudo mv /tmp/suspend-to-ram.sh "$MODULE_DIR/suspend-to-ram.sh"
sudo chmod +x "$MODULE_DIR/suspend-to-ram.sh"

echo "[*] Writing module-setup.sh..."
cat <<'EOF' > /tmp/module-setup.sh
#!/bin/bash

check() {
    return 0
}

depends() {
    echo 'rootfs-block'
    return 0
}

install() {
    inst_hook pre-mount 10 "$moddir/suspend-to-ram.sh"
    inst /usr/bin/date
}
EOF

sudo mv /tmp/module-setup.sh "$MODULE_DIR/module-setup.sh"
sudo chmod +x "$MODULE_DIR/module-setup.sh"

echo "[*] Rebuilding initramfs for kernel $KERNEL_VERSION..."
sudo dracut -f

echo "[✔] Suspend-to-RAM workaround installed successfully."
echo "→ Reboot your system to test."