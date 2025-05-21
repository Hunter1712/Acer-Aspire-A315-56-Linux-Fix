#!/bin/bash

# Create the install file for the suspend-to-ram hook using cat with a here document
cat << 'EOF' > /etc/initcpio/install/suspend-to-ram
#!/bin/bash
build() { 
        add_binary date
        add_runscript
}
help() {
        echo "Suspend to RAM before filesystems get mounted so the initial ramdisk can see the internal storage"
}
EOF

# Make the install file executable
chmod +x /etc/initcpio/install/suspend-to-ram

# Create the hook file for the suspend-to-ram hook using cat with a here document
cat << 'EOF' > /etc/initcpio/hooks/suspend-to-ram
#!/bin/bash
run_hook() {
        FILE='/sys/class/rtc/rtc0/wakealarm'
        EPOCH_TIME="$(date '+%s')"
        if ! echo 0 > "$FILE"; then
                reboot -f
        elif ! echo "$((EPOCH_TIME + 2))" > "$FILE"; then
                reboot -f
        elif ! echo mem > /sys/power/state; then
                reboot -f
        fi
}
EOF

# Make the hook file executable
chmod +x /etc/initcpio/hooks/suspend-to-ram

# Modify the mkinitcpio.conf file to include the suspend-to-ram hook
sed -i 's/HOOKS=(.*/HOOKS=(base udev autodetect microcode modconf kms keyboard keymap consolefont block filesystems suspend-to-ram fsck)/' /etc/mkinitcpio.conf

# Regenerate the initramfs
sudo mkinitcpio -P