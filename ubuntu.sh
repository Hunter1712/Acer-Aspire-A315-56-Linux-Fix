#!/bin/bash

# Exit immediately on error
set -e

# Path to the mounted target system (e.g., the installed Linux system)
TARGET="/target"

# Validate the target directory
if [ ! -d "$TARGET" ] || [ ! -d "$TARGET/etc" ]; then
    echo "Target directory $TARGET is not valid or not mounted. Exiting."
    exit 1
fi

echo "🛠️  Mounting system dirs into $TARGET for chroot..."
# Mount essential pseudo-filesystems into the target environment
for dir in dev proc sys run; do
    mount --bind /$dir "$TARGET/$dir"
done

# Enter chroot and execute script to install suspend-to-RAM workaround
echo "Entering chroot to apply workaround..."
chroot "$TARGET" /bin/bash <<'CHROOT_SCRIPT'
set -e

echo "Applying suspend-to-RAM workaround for Acer Aspire 3 A315-56..."

# Paths to the custom hook and early boot script
HOOK_FILE="/etc/initramfs-tools/hooks/suspend-to-ram"
PREMOUNT_SCRIPT="/etc/initramfs-tools/scripts/init-premount/suspend-to-ram"

# 1. Create initramfs hook
echo "Creating hook at $HOOK_FILE..."
cat << 'EOF' > "$HOOK_FILE"
#!/bin/sh
PREREQ=""

prereqs() {
    echo "$PREREQ"
}

case "$1" in
    prereqs)
        prereqs
        exit 0
        ;;
esac

# Load helper functions for initramfs
. /usr/share/initramfs-tools/hook-functions

# Ensure the 'date' command is available in the initramfs
copy_exec /bin/date /bin
EOF

# Make the hook script executable
chmod +x "$HOOK_FILE"

# 2. Create early boot script to suspend system briefly
echo "Creating init-premount script at $PREMOUNT_SCRIPT..."
cat << 'EOF' > "$PREMOUNT_SCRIPT"
#!/bin/sh
# suspend-to-ram workaround for Acer Aspire 3 A315-56

PREREQ=""

prereqs() {
    echo "$PREREQ"
}

case "$1" in
    prereqs)
        prereqs
        exit 0
        ;;
esac

echo "[suspend-to-ram hook] Forcing suspend to RAM..."

RTC_FILE="/sys/class/rtc/rtc0/wakealarm"
EPOCH_TIME="$(date '+%s')"  # Get current time in seconds since epoch

# Clear any previously set RTC wakealarm
echo 0 > "$RTC_FILE" || reboot -f

# Set a new alarm 2 seconds in the future
echo "$((EPOCH_TIME + 2))" > "$RTC_FILE" || reboot -f

# Suspend system to RAM
echo mem > /sys/power/state || reboot -f

echo "[suspend-to-ram hook] Resumed, continuing boot..."
EOF

# Make the script executable
chmod +x "$PREMOUNT_SCRIPT"

# 3. Update initramfs to include new scripts
echo "Updating initramfs..."
update-initramfs -u

echo "Workaround applied. Reboot the system to take effect."
CHROOT_SCRIPT

# 4. Cleanup: unmount bound directories from target
echo "Cleaning up mounts..."
for dir in run sys proc dev; do
    umount -lf "$TARGET/$dir" || true
done

echo "All done. You may now reboot into the installed system."
