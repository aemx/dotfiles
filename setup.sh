# Verify boot mode (should return 64)
  # cat /sys/firmware/efi/fw_platform_size

# Connect to internet
  # ip link
  # ping archlinux.org

# Set system clock
  # timedatectl

# Enter sudo mode, move to root
  # sudo su

# Prepare partitions
  # cfdisk

# select gpt
  # [sda1] 1G for EFI System / boot
  # [sda2] 4G+ for Linux swap
  # [sda3] remaining for Linux root (x86_64)
  # Write partitions, Exit

if [[ $1 == "1" ]]; then

  # Confirm partitioning
  lsblk

  # Build file systems
  mkfs.ext4 -L os /dev/sda3
  mkfs.fat -F32 -n boot /dev/sda1
  mkswap -L swap /dev/sda2

  # Mount file systems, confirm
  mount /dev/disk/by-label/os /mnt
  mkdir -p /mnt/boot
  mount /dev/disk/by-label/boot /mnt/boot
  swapon /dev/sda2
  lsblk

  # Install essential packages
  pacstrap -K /mnt base base-devel linux linux-firmware intel-ucode git sudo micro zsh unzip zip grub efibootmgr

  # Generate an fstab file
  genfstab -U /mnt >> /mnt/etc/fstab

################################################################################

# Change root into the new system
  # arch-chroot /mnt

################################################################################

elif [[ $1 == "2" ]]; then

  # Generate time zone and locale files
  ln -sf /usr/share/zoneinfo/America/Chicago /etc/localtime
  hwclock --systohc
  locale-gen
  echo LANG=en_US.UTF-8 > /etc/locale.conf
  sed -e '/en_US/s/^#*//g' -i /etc/locale.gen
  locale-gen

  # Create hostname file
  echo virt > /etc/hostname

  # Create new initramfs (For LVM, system encryption or RAID, modify mkinitcpio.conf)
  mkinitcpio -P

  # Set root password
  passwd

  # Install grub
  grub-install --target=x86_64-efi --efi-directory=boot --bootloader-id=GRUB
  grub-mkconfig -o /boot/grub/grub.cfg

  # Preemptive post-reboot network setup
  systemctl enable systemd-networkd
  systemctl enable systemd-resolved
  printf "[Match]\nName=$(ls /sys/class/net/ | grep -v lo)\n\n[Network]\nDHCP=yes\n" > /etc/systemd/network/20-wired.network

  # Enable parallel downloads on pacman
    # sed -i '/ParallelDownloads/s/^#//g' /etc/pacman.conf

  # Set up users/groups/sudoers
  sed -i '/%wheel ALL=(ALL:ALL) ALL/s/^# //g' /etc/sudoers
  useradd -m -G wheel -s /usr/bin/zsh ceri
  passwd ceri

  # Load configurations
  git clone https://github.com/aemx/dotfiles ~/tmp/dotfiles
  cp -R ~/tmp/dotfiles/home ~
  cp -R ~/tmp/dotfiles/usr /usr
  cp -R ~/tmp/dotfiles/etc /etc

  # Clean up and reboot
  exit
  umount -R /mnt
  reboot

elif [[ $1 == "3" ]]; then

  # Check for hardware vulnerabilities (not required for a VM)
    # lscpu

  # Update keyrings
  sudo pacman-key --init
  sudo pacman-key --populate
  sudo pacman-key --refresh-keys # Ignore errors
  sudo pacman -Sy archlinux-keyring

  # Automate package cache cleaning
  sudo pacman -S pacman-contrib
  sudo systemctl enable paccache.timer
  sudo paccache -rk1

  # Install AUR dependencies (nosudo)
  ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
  git clone https://aur.archlinux.org/yay.git
  cd yay
  makepkg -si
  cd ..
  rm -rf yay

  # Install VirtualBox utils
  pacman -S virtualbox-guest-utils

  # BEGIN INSTALLATION ========================================================

  for file in ~/tmp/dotfiles/pkgs/*.ceripkg; do
    while read -r line; do
      strarr=($line)
      if [[ ${strarr[0]} == "y" ]]; then
        printf "\e[30;105mInstalling ${strarr[1]}...\e[m\n"
        yay -S ${strarr[1]} --noconfirm
      elif [[ ${strarr[0]} == "-" ]]; then
        printf "\e[30;105mInstalling ${strarr[1]}...\e[m\n"
        sudo pacman -S ${strarr[1]} --noconfirm
      fi
    done <$file
  done

  # exceptions
  # create.fadein
  # dev.nvm
  printf "\e[30;105mInstalling steam...\e[m\n"
  sudo pacman -Sy steam
  # tools.discordchatexporter
  # tools.nine-or-null
  # tools.ntsc-rs

  # Clear yay cache
  yay -Sc --noconfirm

  # END INSTALLATION ==========================================================

  # Set up DM, lockscreen
  systemctl enable lightdm.service
    # xfconf-query --create -c xfce4-session -p /general/LockCommand -t string -s "light-locker-command --lock"

  # Set up virt-manager
  systemctl enable libvirtd.socket

  # With plymouth, change mkinitcpio's hooks
  plymouth-set-default-theme -R arch10

  # Download cursors
  curl -L https://github.com/birbkeks/windows-cursors/releases/download/1.0/windows-cursors.tar.gz > ~/tmp/windows-cursors.tar.gz
  tar -xzvf desktop/windows-cursors.tar.gz -C ~/.icons
  rm -rf ~/tmp

  # TODO: config mpv

  # Reboot
  reboot

fi