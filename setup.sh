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

  # Build file systems
  mkfs.ext4 -L arch /dev/sda3
  mkfs.fat -F32 -n boot /dev/sda1
  mkswap -L swap /dev/sda2

  # Mount file systems
  mount /dev/disk/by-label/arch /mnt
  mkdir -p /mnt/boot
  mount /dev/disk/by-label/boot /mnt/boot
  swapon /dev/sda2

  # Install essential packages
  pacstrap -K /mnt base base-devel linux linux-firmware intel-ucode git sudo micro zsh unzip zip grub efibootmgr lib32-systemd

  # Generate an fstab file
  genfstab -U /mnt >> /mnt/etc/fstab

################################################################################

# Confirm filesystem
  # lsblk

# Change root into the new system
  # arch-chroot /mnt

# Create hostname file
  # echo hostname_name > /etc/hostname

################################################################################

elif [[ $1 == "2" ]]; then

  # Generate time zone and locale files
  ln -sf /usr/share/zoneinfo/America/Chicago /etc/localtime
  hwclock --systohc
  locale-gen
  echo LANG=en_US.UTF-8 > /etc/locale.conf
  sed -e '/en_US/s/^#*//g' -i /etc/locale.gen
  locale-gen

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

  # Enable color, parallel downloads, and multilib on pacman
  sed -i 's|#Color|Color|g' /etc/pacman.conf
  sed -i 's|#ParallelDownloads = 5|ParallelDownloads = 10|g' /etc/pacman.conf
  sed -i "/\[multilib\]/,/Include/"'s/^#//' /etc/pacman.conf

  # Set up users/groups/sudoers
  sed -i '/%wheel ALL=(ALL:ALL) ALL/s/^# //g' /etc/sudoers
  useradd -m -G wheel -s /usr/bin/zsh ceri
  passwd ceri

  # Clean up and reboot
    # exit
    # umount -R /mnt
    # reboot

elif [[ $1 == "3" ]]; then

  if [ -z "$2" ]; then
    echo "No arguments provided"
    exit 1
  fi

  # Begin load configurations (usr, etc)
  git clone https://github.com/aemx/dotfiles ~/tmp/dotfiles

  # Update package database
  sudo pacman -Syu

  # Check for hardware vulnerabilities (not required for a VM)
    # lscpu

  # Update keyrings
  sudo pacman-key --init
  sudo pacman-key --populate
  sudo pacman-key --refresh-keys # Ignore errors
  sudo pacman -Sy archlinux-keyring --noconfirm

  # Automate package cache cleaning
  sudo pacman -S pacman-contrib --noconfirm
  sudo systemctl enable paccache.timer
  sudo paccache -rk1

  # resolv.conf
  ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf

  # Install paru
  git clone https://aur.archlinux.org/paru.git
  cd paru
  makepkg -si
  cd ..
  rm -rf paru

  # Install VirtualBox utils
    # sudo pacman -S virtualbox-guest-utils --noconfirm

  # Install Dropbox public key
  curl https://linux.dropbox.com/fedora/rpm-public-key.asc > rpm-public-key.asc
  gpg --import rpm-public-key.asc
  rm rpm-public-key.asc

  # BEGIN INSTALLATION ========================================================

  for file in ~/tmp/dotfiles/pkgs/*.ceripkg; do
    while read -r line; do
      strarr=($line)
      bin=$(printf "%d" "$((2#${strarr[0]}))")
      if [[ $(( $bin & (1 << ($1 - 1)) )) >0 ]]; then
        if [[ ${strarr[1]} == "a" ]]; then
          printf "\e[30;105mInstalling ${strarr[2]}...\e[m\n"
          paru -S ${strarr[2]} --noconfirm
        elif [[ ${strarr[1]} == "-" ]]; then
          printf "\e[30;105mInstalling ${strarr[2]}...\e[m\n"
          sudo pacman -S ${strarr[2]} --noconfirm
        fi
      fi
    done <$file
  done

  # Clear paru cache
  paru -Sc --noconfirm

  # Load configurations (home folder)
  cp -a ~/tmp/dotfiles/home/. ~

  # END INSTALLATION ==========================================================

  # Set up DM, lockscreen
  systemctl enable lightdm.service
    # xfconf-query --create -c xfce4-session -p /general/LockCommand -t string -s "light-locker-command --lock"

  # Add plymouth theme, change mkinitcpio's hooks
  sudo plymouth-set-default-theme -R arch10
  sudo sed -i 's|^\(HOOKS.*fsck\)|\1 plymouth|g' /etc/mkinitcpio.conf
  mkinitcpio -P

  # Set up virt-manager
  systemctl enable libvirtd.socket


  # Download XFCE4 theme
  - Download theme to 
  git clone https://github.com/aemx/ceres-gtk /home/ceri/.themes/ceres

  # Download login/lock theme
  git clone https://github.com/aemx/winluxe-greeter /usr/share/web-greeter/themes/winluxe

  # Download icon theme
  git clone https://github.com/B00merang-Artwork/Windows-10 /home/ceri/.icons/win10

  # Download cursors
  curl -L https://github.com/birbkeks/windows-cursors/releases/download/1.0/windows-cursors.tar.gz > ~/tmp/windows-cursors.tar.gz
  tar -xzvf ~/tmp/windows-cursors.tar.gz -C ~/.icons

  # Uninstall xfce4-terminal
  sudo pacman -Rncs xfce4-terminal --noconfirm

  # Copy configs, set permissions properly
    # cp -a ~/tmp/dotfiles/usr/. /usr
    # cp -a ~/tmp/dotfiles/etc/. /etc

  # Install manually
    # 011 create.fadein
    # 111 dev.nvm
    # 011 tools.discordchatexporter
    # 011 tools.nine-or-null
    # 001 tools.ntsc-rs
  
  # Wine/vm
    # arrowvortex
    # flashpoint
    # fl studio
    # illustrator
    # medibang
    # notitg
    # nostalgia stuff
    # photoshop
    # pushbullet(?)
    # skyperious

  # Reboot
    # sudo reboot

fi