#!/usr/bin/env zsh

set -e  # Arrêter en cas d'erreur

### 🌍 Configuration du réseau ###
timedatectl set-ntp true

### 🏗️ Partitionnement (remplace /dev/sdX par ton disque) ###
DISK="/dev/sdX"

echo "Partitionnement du disque..."
parted $DISK --script mklabel gpt
parted $DISK --script mkpart primary fat32 1MiB 512MiB
parted $DISK --script set 1 esp on
parted $DISK --script mkpart primary linux-swap 512MiB 4GiB
parted $DISK --script mkpart primary ext4 4GiB 100%

### 📀 Formatage des partitions ###
mkfs.fat -F32 ${DISK}1
mkswap ${DISK}2
mkfs.ext4 ${DISK}3

### 🔄 Montage des partitions ###
mount ${DISK}3 /mnt
mkdir -p /mnt/boot
mount ${DISK}1 /mnt/boot
swapon ${DISK}2

### 📦 Installation du système de base ###
pacstrap /mnt base linux linux-firmware vim grub efibootmgr networkmanager zsh

### 📋 Génération du fstab ###
genfstab -U /mnt >> /mnt/etc/fstab

### 🛠 Configuration du système ###
arch-chroot /mnt zsh <<EOF
ln -sf /usr/share/zoneinfo/Europe/Paris /etc/localtime
hwclock --systohc

echo "LANG=fr_FR.UTF-8" > /etc/locale.conf
echo "KEYMAP=fr" > /etc/vconsole.conf
locale-gen

echo "archlinux" > /etc/hostname
echo "127.0.0.1 localhost" >> /etc/hosts
echo "::1       localhost" >> /etc/hosts
echo "127.0.1.1 archlinux.localdomain archlinux" >> /etc/hosts

# 🔑 Mot de passe root
echo "root:toor" | chpasswd

# 🏁 Installation de GRUB
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

# 🚀 Activer le réseau au démarrage
systemctl enable NetworkManager

# 🐚 Définir Zsh comme shell par défaut
chsh -s /bin/zsh root
EOF

echo "Installation terminée ! Vous pouvez redémarrer."
