#!/bin/bash
# vars
url=$1
# remove ALL LVS
lvremove -f `lvscan | cut -d"'" -f2 | xargs`
# remove ALL LVG
vgremove -f `vgscan | grep Found | cut -d'"' -f2| xargs`
# get ALL DISK
#disks=`lsblk | grep disk | cut -d" " -f1| xargs`
# create new MBR on the sda
SECTORS=`fdisk -l /dev/sda | grep "Disk /dev/sda" | cut -d"," -f3 | xargs | cut -d" " -f1`

echo "label: dos" > /tmp/tmp.blk
echo "label-id: 0xac28acd7" >> /tmp/tmp.blk
echo "device: /dev/sda" >> /tmp/tmp.blk
echo "unit: sectors" >> /tmp/tmp.blk
echo "" >> /tmp/tmp.blk
echo "/dev/sda1 : start=        2048, size=     1048576, type=83" >> /tmp/tmp.blk
echo "/dev/sda2 : start=     1050624, size=    $SECTORS, type=83" >> /tmp/tmp.blk

sfdisk /dev/sda < /tmp/tmp.blk
rm -f /tmp/tmp.blk
# create VG
vgcreate vg0 /dev/sda2 -f
# create lvm
lvcreate -L 1G -n swap vg0
lvcreate -l 100%free -n root vg0

# create fs sda1
mkfs.ext2 -F /dev/sda1
mkfs.ext4 -F /dev/vg0/root
mkswap -f /dev/vg0/swap

# mount
cd /mnt&&mkdir disk
mount /dev/vg0/root disk
cd disk
mkdir boot && mount /dev/sda1 boot

wget $url

tar xf ubuntu-18-image.tar.gz
#cat /etc/resolv.conf >> etc/resolv.conf
mount -t proc proc proc/
mount -t sysfs sys sys/
mount -o bind /dev dev/



target=`cat /mnt/disk/etc/fstab | grep " /boot " | grep " ext2 " | cut -d" " -f1`;dest1=`blkid | grep sda1 | cut -d" " -f2| sed -e 's/"//g'`;sed -i -e "s/$target/$dest1/" /mnt/disk/etc/fstab



chroot /mnt/disk grub-install /dev/sda
chroot /mnt/disk grub-mkconfig -o /boot/grub/grub.cfg
chroot /mnt/disk chown daemon:daemon /var/spool/cron/atjobs
chroot /mnt/disk chown daemon:daemon /var/spool/cron/atspool
