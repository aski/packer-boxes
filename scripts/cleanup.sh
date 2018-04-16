DISK_USAGE_BEFORE_CLEANUP=$(df -h)

echo "==> Clear out machine id"
rm -f /etc/machine-id
touch /etc/machine-id

echo "==> Remove mac addresses from network config files"
rm -f /etc/udev/rules.d/70-persistent-net.rules

for ifcfg in $(ls /etc/sysconfig/network-scripts/ifcfg-*)
do
    if [ "$(basename ${ifcfg})" != "ifcfg-lo" ]
    then
        sed -i '/^UUID/d'   "${ifcfg}"
        sed -i '/^HWADDR/d' "${ifcfg}"
    fi
done

echo "==> Remove rescue kernel"
rm -f /boot/initramfs*rescue*
rm -r /boot/vmlinuz-0-rescue-*
grub2-mkconfig -o /boot/grub2/grub.cfg

echo "==> Remove old kernels"
yum install -y -q yum-utils
package-cleanup --oldkernels --count=1 -y -q

echo "==> Clear yum cache"
yum -y clean all
rm -rf /var/cache/yum

echo "==> Rebuild rpm deb and delete cache"
rm -rf /var/lib/rpm/__*
rpmdb --rebuilddb -v -v

echo "==> Remove all files from /root"
rm -rf /root/*

echo "==> Delete root's bash history"
unset HISTFILE
rm -f /root/.bash_history

echo "==> Clear tmp directory"
rm -rf /tmp/*

echo "==> Blank out all files in /var/log"
find /var/log -type f | while read f; do echo -ne '' > $f; done;

echo "==> Clear out swap space"
set +e
swapuuid=$(/sbin/blkid -o value -l -s UUID -t TYPE=swap)
case "$?" in
    2|0) ;;
    *) exit 1 ;;
esac
set -e
if [ "x${swapuuid}" != "x" ]; then
    # Whiteout the swap partition to reduce box size
    # Swap is disabled till reboot
    swappart=$(readlink -f /dev/disk/by-uuid/$swapuuid)
    /sbin/swapoff "${swappart}"
    dd if=/dev/zero of="${swappart}" bs=1M || echo "dd exit code $? is suppressed"
    /sbin/mkswap -U "${swapuuid}" "${swappart}"
fi

echo "==> Zero all blank space on /boot"
dd if=/dev/zero of=/boot/EMPTY bs=1M | true
rm -f /boot/EMPTY

echo "==> Zero all blank space on /"
dd if=/dev/zero of=/EMPTY bs=1M | true
rm -f /EMPTY

sync
sleep 30

echo "==> Disk usage before cleanup"
echo "${DISK_USAGE_BEFORE_CLEANUP}"

echo "==> Disk usage after cleanup"
df -h
