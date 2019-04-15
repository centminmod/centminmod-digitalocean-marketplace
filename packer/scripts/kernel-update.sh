#!/bin/bash
#####################################################################
# elrepo kernel-ml updater that takes care of grub2-mkconfig run
#####################################################################
yuminstalled_kernel=$(yum -q info kernel-ml | awk '/Version/ {print $3}' | tail -1| awk -F. '{ printf("%d%03d%03d%03d\n", $1,$2,$3,$4); }')
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
  # only proceed further if yum installed kernel-ml version is greater than
  # version listed on uname -r output
  if [[ "$yuminstalled_kernel" -ge "$unamer_kernel" ]]; then
    echo "update /boot/grub2/grub.cfg"
    echo
    echo "grub2-set-default 0"
    grub2-set-default 0
    echo "grub2-mkconfig -o /boot/grub2/grub.cfg"
    grub2-mkconfig -o /boot/grub2/grub.cfg
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