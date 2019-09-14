#!/bin/bash
#####################################################################
# elrepo kernel-ml updater that takes care of grub2-mkconfig run
#####################################################################
unamer_kernel=$(uname -r | awk -F. '{ printf("%d%03d%03d%03d\n", $1,$2,$3,$4); }')

update_kernel() {
  if [[ "$unamer_kernel" -ge '5000007000' ]]; then
  echo "updating elrepo kernel-ml packages"
  echo
  echo "yum clean all"
  yum clean all
  echo
  echo "yum -y update kernel-ml kernel-ml-devel kernel-ml-tools --enablerepo=elrepo-kernel"
  yum -y update kernel-ml kernel-ml-devel kernel-ml-tools --enablerepo=elrepo-kernel
  echo
  yuminstalled_kernel=$(yum -q info kernel-ml | awk '/Version/ {print $3}' | tail -1| awk -F. '{ printf("%d%03d%03d%03d\n", $1,$2,$3,$4); }')
  # only proceed further if yum installed kernel-ml version is greater than
  # version listed on uname -r output
  if [[ "$yuminstalled_kernel" -gt "$unamer_kernel" ]]; then
    if [[ "$(lsblk | grep nvme)" && -d /boot/efi/EFI/centos ]]; then
      if [ ! -f /usr/sbin/efibootmgr ]; then
        yum -q -y install efibootmgr
      fi
      # check EFI bios support
      check_efibios=$(efibootmgr 2>&1 | grep -o 'not supported')
      check_bootefi=$(df -P --local | grep nvme | grep -o '/boot/efi')
      check_grubefi=$(egrep 'linuxefi|initrdefi' /boot/grub2/grub.cfg)
      check_grub_noefi=$(egrep 'linux16|initrd16' /boot/grub2/grub.cfg)
    fi
    if [[ "$check_grubefi" && "$check_bootefi" = '/boot/efi' && "$check_efibios" != 'not supported' && "$(lsblk | grep nvme)" && -d /boot/efi/EFI/centos && -d /sys/firmware/efi ]]; then
    # if [[ "$(lsblk | grep nvme)" && -d /boot/efi/EFI/centos ]]; then
      echo "update /boot/efi/EFI/centos/grub.cfg"
    else
      echo "update /boot/grub2/grub.cfg"
    fi
    echo
    echo "grub2-set-default 0"
    grub2-set-default 0
    if [[ "$check_grubefi" && "$check_bootefi" = '/boot/efi' && "$check_efibios" != 'not supported' && "$(lsblk | grep nvme)" && -d /boot/efi/EFI/centos && -d /sys/firmware/efi ]]; then
    # if [[ "$(lsblk | grep nvme)" && -d /boot/efi/EFI/centos ]]; then
      echo "grub2-mkconfig -o /boot/efi/EFI/centos/grub.cfg"
      grub2-mkconfig -o /boot/efi/EFI/centos/grub.cfg
      ls -lah /boot/efi/EFI/centos/grub.cfg
      ls -lah /etc/grub2-efi.cfg
    else
      echo "grub2-mkconfig -o /boot/grub2/grub.cfg"
      grub2-mkconfig -o /boot/grub2/grub.cfg
    fi
    echo
    echo "grub2-editenv list"
    grub2-editenv list
    echo
    echo "elrepo kernel-ml updated"
    echo "system requires reboot"
  fi
fi
}

update_kernel