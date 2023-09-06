#!/usr/bin/env bash

echo "Please enter EFI paritition: (example /dev/sda1 or /dev/nvme0n1p1)"
read EFI

echo "Please enter SWAP paritition: (example /dev/sda2)"
read SWAP

echo "Please enter Root(/) paritition: (example /dev/sda3)"
read ROOT 

echo "Please enter your username"
read USER 

echo "Please enter your password"
read PASSWORD 

# make filesystems
echo -e "\nCreating Filesystems...\n"

mkfs.vfat -F32 -n "EFISYSTEM" "${EFI}"
mkswap "${SWAP}"
swapon "${SWAP}"
mkfs.btrfs -L "ROOT" "${ROOT}"

# mount target
mount -t btrfs "${ROOT}" /mnt
mkdir /mnt/boot
mount -t vfat "${EFI}" /mnt/boot/

echo "INSTALLING Arch Linux BASE on Main Drive"
pacstrap /mnt base base-devel --noconfirm --needed

# kernel
pacstrap /mnt linux linux-firmware --noconfirm --needed

echo "Setup Dependencies"

pacstrap /mnt networkmanager network-manager-applet wireless_tools vim intel-ucode bluez bluez-utils blueman git --noconfirm --needed

# fstab
genfstab -U /mnt >> /mnt/etc/fstab

echo "Bootloader Installing"
bootctl install --path /mnt/boot
echo "default arch.conf" >> /mnt/boot/loader/loader.conf
cat <<EOF > /mnt/boot/loader/entries/arch.conf
title Arch Linux
linux /vmlinuz-linux
initrd /initramfs-linux.img
options root=${ROOT} rw
EOF


cat <<REALEND > /mnt/next.sh
useradd -m $USER
usermod -aG wheel,storage,power,audio $USER
echo $USER:$PASSWORD | chpasswd
sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

echo "Setup Language to US and set locale"
sed -i 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" >> /etc/locale.conf

ln -sf /usr/share/zoneinfo/Australia/Melbourne /etc/localtime
hwclock --systohc

echo "arch" > /etc/hostname
cat <<EOF > /etc/hosts
127.0.0.1	localhost
::1			localhost
127.0.1.1	arch.localdomain	arch
EOF

echo "installing graphics and audio stuff"

pacman -S libx11 libxft xorg-server xorg-xinit pipewire --noconfirm --needed

systemctl enable NetworkManager bluetooth

# Window manager install

mkdir /home/$USER/SysStuff
git clone https://github.com/niforru/dwm
git clone https://github.com/niforru/st
git clone https://github.com/niforru/dmenu

echo "Install Complete, You can reboot now"

REALEND


arch-chroot /mnt sh next.sh
