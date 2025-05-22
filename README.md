# 🛠 Suspend-to-RAM Workaround: Full Guide (Chroot to Execution)

This guide helps users apply a suspend-to-RAM workaround from a live USB environment (e.g., after fresh install, before first boot), including all chroot steps and script execution, tailored for each supported Linux distribution.

## ⚙️ Prerequisites

A Linux system that fails to detect the SATA drive at boot without suspend/resume.

A live USB/rescue environment.

Your target root partition (e.g., /dev/sda2).

This repository cloned or copied to a USB drive or downloaded to the live environment.

## Debian / Ubuntu / Pop!_OS (initramfs-tools)

✅ No manual chroot required

Boot into the live USB.

Mount the installed system:

    sudo mount /dev/sdXn /target  # Replace sdXn with your root partition

If the script is on a USB drive, identify and mount it:

    lsblk                             # Find your USB device
    mkdir -p /mnt/usb
    sudo mount /dev/sdY1 /mnt/usb     # Replace sdY1 with your USB partition
    cd /mnt/usb
    chmod +x ubuntu.sh

Run the script:

    sudo ./ubuntu.sh

## Arch Linux / Manjaro (mkinitcpio)

⚠️ Manual chroot required

Boot into the live USB.

Mount the installed system:

    sudo mount /dev/sdXn /mnt

If the script is on a USB drive:

    lsblk
    mkdir -p /mnt/usb
    sudo mount /dev/sdY1 /mnt/usb
    cp -r /mnt/usb /mnt/root/workaround   # Or any location inside root

Chroot into the installed system:

    sudo arch-chroot /mnt
    cd /root/workaround                    # Or the location you used
    chmod +x archlinux.sh
    ./archlinux.sh

## Fedora / RHEL / AlmaLinux (dracut)

⚠️ Manual chroot required

Boot into the live USB.

Mount and bind:

    sudo mount --bind /dev /mnt/sysroot/dev
    sudo mount --bind /proc /mnt/sysroot/proc
    sudo mount --bind /sys /mnt/sysroot/sys
    sudo mount --bind /run /mnt/sysroot/run

If the script is on a USB drive:

    lsblk
    mkdir -p /mnt/sysroot/mnt/usb
    sudo mount /dev/sdY1 /mnt/sysroot/mnt/usb

Chroot and run:

    sudo chroot /mnt/sysroot
    cd /mnt/usb
    chmod +x fedora.sh
    ./fedora.sh


## ✅ After Reboot

When you reboot:

The screen should briefly go black, then resume.

Your SATA/root drive should now be detected.

The boot process continues as normal.

## 🧼 Uninstall Instructions
### Debian / Ubuntu

    sudo rm /etc/initramfs-tools/hooks/suspend-to-ram
    sudo rm /etc/initramfs-tools/scripts/init-premount/suspend-to-ram
    sudo update-initramfs -u

### Arch Linux

    sudo rm /etc/initcpio/hooks/suspend-to-ram
    sudo rm /etc/initcpio/install/suspend-to-ram
    sudo sed -i 's/ suspend-to-ram//' /etc/mkinitcpio.conf
    sudo mkinitcpio -P

### Fedora / RHEL

    sudo rm -rf /usr/lib/dracut/modules.d/90suspend-to-ram
    sudo dracut -f

## 🧾 Credits

[Arch Wiki workaround for Acer Aspire A315-56](https://wiki.archlinux.org/title/Laptop/Acer#Aspire_3_A315-56_internal_storage_not_showing_up)

## 📜 License

MIT License – Use at your own risk.