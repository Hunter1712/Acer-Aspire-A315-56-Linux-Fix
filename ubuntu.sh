#!/bin/bash

# fix-sata-suspend-in-target.sh
# Apply SATA suspend workaround in /target (e.g. mounted /dev/sdb2)

set -e

TARGET="/target"

if [ ! -d "$TARGET" ] || [ ! -d "$TARGET/etc" ]; then
    echo "❌ Target directory $TARGET is not valid or not mounted. Exiting."
    exit 1
fi

echo "🛠️  Mounting system dirs into $TARGET for chroot..."
for dir in dev proc sys run; do
    mount --bind /$dir "$TARGET/$dir"
done

echo "🔁 Entering chroot to apply workaround..."
chroot "$TARGET" /bin/bash <<'CHROOT_SCRIPT'
set -e

echo "⚙️  Applying suspend-to-RAM workaround for Acer Aspire 3 A315-56..."

HOOK_FILE="/etc/initramfs-tools/hooks/suspend-to-ram"
PREMOUNT_SCRIPT="/etc/initramfs-tools/scripts/init-premount/suspend-to-ram"

# 1. Create initramfs hook
echo "📄 Creating hook at $HOOK_FILE..."
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

. /usr/share/initramfs-tools/hook-functions

copy_exec /bin/date /bin
EOF

chmod +x "$HOOK_FILE"

# 2. Create early boot script
echo "📄 Creating init-premount script at $PREMOUNT_SCRIPT..."
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
EPOCH_TIME="$(date '+%s')"

# Clear any existing RTC alarm
echo 0 > "$RTC_FILE" || reboot -f

# Set alarm to 2 seconds in the future
echo "$((EPOCH_TIME + 2))" > "$RTC_FILE" || reboot -f

# Suspend to RAM
echo mem > /sys/power/state || reboot -f

echo "[suspend-to-ram hook] Resumed, continuing boot..."
EOF

chmod +x "$PREMOUNT_SCRIPT"

# 3. Update initramfs
echo "🔃 Updating initramfs..."
update-initramfs -u

echo "✅ Workaround applied. Reboot the system to take effect."
CHROOT_SCRIPT

# 4. Cleanup
echo "🧹 Cleaning up mounts..."
for dir in run sys proc dev; do
    umount -lf "$TARGET/$dir" || true
done

echo "✅ All done. You may now reboot into the installed system."