#!/bin/bash
# Exit on error, undefined variable, or pipe failure
set -euo pipefail

# Name and path for the custom Dracut module
MODULE_NAME="90suspend-to-ram"
MODULE_DIR="/usr/lib/dracut/modules.d/$MODULE_NAME"

echo "[*] Creating Dracut module directory..."
# Create the Dracut module directory if it doesn't exist
sudo mkdir -p "$MODULE_DIR"

echo "[*] Writing suspend-to-ram.sh hook..."
# Create the suspend-to-ram hook script
cat <<'EOF' > /tmp/suspend-to-ram.sh
#!/bin/sh

# This script sets a short RTC wake alarm and suspends the system to RAM

echo 'Executing suspend-to-ram hook...'

FILE='/sys/class/rtc/rtc0/wakealarm'
EPOCH_TIME="$(date '+%s')"  # Get current epoch time

# Clear any previously set RTC wake alarm
echo 0 > "$FILE" || reboot -f

# Set a new wake alarm 2 seconds in the future
echo "$((EPOCH_TIME + 2))" > "$FILE" || reboot -f

# Suspend the system to RAM
echo mem > /sys/power/state || reboot -f
EOF

# Move the hook script into the Dracut module directory and make it executable
sudo mv /tmp/suspend-to-ram.sh "$MODULE_DIR/suspend-to-ram.sh"
sudo chmod +x "$MODULE_DIR/suspend-to-ram.sh"

echo "[*] Writing module-setup.sh..."
# Create the Dracut module setup script
cat <<'EOF' > /tmp/module-setup.sh
#!/bin/bash

# Always include this module
check() {
    return 0
}

# Declare dependency on rootfs-block to ensure it's included
depends() {
    echo 'rootfs-block'
    return 0
}

# Install the suspend hook into the initramfs
install() {
    inst_hook pre-mount 10 "$moddir/suspend-to-ram.sh"
    inst /usr/bin/date  # Ensure the 'date' command is available in the initramfs
}
EOF

# Move the setup script into the module directory and make it executable
sudo mv /tmp/module-setup.sh "$MODULE_DIR/module-setup.sh"
sudo chmod +x "$MODULE_DIR/module-setup.sh"

echo "[*] Rebuilding initramfs for kernel $KERNEL_VERSION..."
# Rebuild the initramfs to include the new module
sudo dracut -f

echo "[✔] Suspend-to-RAM workaround installed successfully."
echo "→ Reboot your system to test."
