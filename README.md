# Acer-Aspire-A315-56-Linux-Fix

# Suspend-to-RAM Workaround for Linux Systems

This repository provides a workaround for Suspend-to-RAM (S3 sleep) issues on certain laptops such as the **Acer Aspire 3 A315-56**. It sets an RTC wakealarm to wake the system after a brief suspend during early boot, allowing the kernel to properly detect SATA storage.

## ⚠️ Important Notice

**Only follow the instructions for your Linux distribution family.**  
This workaround supports:

- **Debian/Ubuntu/Pop!_OS** (uses `initramfs-tools`)
- **Arch Linux/Manjaro** (uses `mkinitcpio`)
- **Fedora/RHEL/AlmaLinux** (uses `dracut`)

## 🧪 What It Does

1. Sets an RTC wake alarm for 2 seconds in the future.
2. Immediately suspends the system to RAM (`echo mem > /sys/power/state`).
3. The system resumes from RTC wakeup and continues booting, resolving early SATA detection problems.

## 🧩 Chroot Instructions (If Applying from Live USB)

If you're applying this workaround right after installing Linux but before your first reboot (e.g., from a live USB or rescue environment), you may need to chroot into your installed system depending on your distribution.

Follow the instructions for your distro:
### 🟦 Ubuntu / Debian / Pop!_OS (initramfs-tools)

✅ Automatic chrooting – No manual chroot needed.

The ubuntu.sh script:

Detects the installation target directory /target (default for installers like Ubiquity),

Binds necessary system directories (/dev, /proc, /sys, /run),

Enters a chroot automatically and applies the workaround.

Just run the script normally after booting the live USB and mounting your system at /target.

### 🟧 Arch Linux / Manjaro (mkinitcpio)

⚠️ Manual chroot required if running from a live environment.

Before running the archlinux.sh script, mount your root partition and chroot manually:

    mount /dev/sdXn /mnt               # Replace /dev/sdXn with your root partition
    arch-chroot /mnt

Then run:

    bash /path/to/archlinux.sh

This is required because mkinitcpio must be run inside the installed system’s environment.

### 🟥 Fedora / RHEL / AlmaLinux (dracut)

⚠️ Manual chroot required if applying from a live USB or rescue mode.

Fedora-based installers mount the installed system at /mnt/sysroot or /mnt/sysimage. Adjust if needed.

Mount and bind system directories, then chroot:

    mount --bind /dev /mnt/sysroot/dev
    mount --bind /proc /mnt/sysroot/proc
    mount --bind /sys /mnt/sysroot/sys
    mount --bind /run /mnt/sysroot/run

    chroot /mnt/sysroot

Run the script inside the chroot:

    bash /path/to/fedora.sh

Use /mnt/sysimage instead of /mnt/sysroot if that matches your environment.

Dracut builds the initramfs for the environment it runs in, so chrooting ensures the initramfs rebuild targets your installed system.

## 🔌 Running the Script from USB Inside the Chroot

If your script is on a USB drive and you are already inside the chroot, do the following:

Identify your USB device:

    lsblk

Create a mount point inside the chroot (e.g., /mnt/usb):

    mkdir -p /mnt/usb

Mount the USB device:

    mount /dev/sdX1 /mnt/usb      # Replace /dev/sdX1 with your USB device partition

Change directory to the USB mount point:

    cd /mnt/usb

Make the script executable and run it:

    chmod +x your-script.sh
    ./your-script.sh

Add sudo if needed


## Running The Scripts
## 🟦 For Ubuntu / Debian (initramfs-tools)

Run the Script

    sudo ./ubuntu.sh

This will:

Create the necessary hook and script.

Update initramfs.

Clean up and prompt you to reboot.

## 🟧 For Arch Linux / Manjaro (mkinitcpio)

Run:

    sudo ./archlinux.sh

This script will:

Create the hook in /etc/initcpio/hooks/suspend-to-ram

Create the install file in /etc/initcpio/install/suspend-to-ram

Insert the hook into your HOOKS=(...) array in /etc/mkinitcpio.conf

Rebuild the initramfs with mkinitcpio -P

Afterward, reboot to test.

## 🟥 For Fedora / RHEL / AlmaLinux (dracut)

Run:

    sudo ./fedora.sh

This will:

Create a custom Dracut module under /usr/lib/dracut/modules.d/90suspend-to-ram/

Include the suspend hook and module-setup script

Rebuild the initramfs using dracut -f

After this, reboot your system.

## ✅ Verifying It Works

Reboot your machine.

You should briefly notice your screen going black then on again indicating a suspend/resume.

Your root device (SATA) should now be detected, and boot continues normally.

## 🧼 Uninstall Instructions

Depending on your system:

### ubuntu:

    sudo rm /etc/initramfs-tools/hooks/suspend-to-ram
    sudo rm /etc/initramfs-tools/scripts/init-premount/suspend-to-ram
    sudo update-initramfs -u

### archlinux:

    sudo rm /etc/initcpio/hooks/suspend-to-ram
    sudo rm /etc/initcpio/install/suspend-to-ram
    sudo sed -i 's/ suspend-to-ram//' /etc/mkinitcpio.conf
    sudo mkinitcpio -P

### fedora:

    sudo rm -rf /usr/lib/dracut/modules.d/90suspend-to-ram
    sudo dracut -f

## 🛟 Troubleshooting

System doesn’t suspend/resume: Ensure your laptop supports S3 and that the wakealarm can be written to /sys/class/rtc/rtc0/wakealarm.

No root device detected still: Boot with a live USB and check /dmesg output for disk detection issues.

RTC file missing: Some systems may use a different RTC device (e.g., rtc1 instead of rtc0).

## 🧾 Credits

This workaround is based on kernel community discussions about suspend-to-RAM workarounds for early boot device detection from the archwiki

https://wiki.archlinux.org/title/Laptop/Acer#Aspire_3_A315-56_internal_storage_not_showing_up

## 📜 License

MIT License – use at your own risk.


