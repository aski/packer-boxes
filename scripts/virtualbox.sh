#! /usr/bin/env bash

set -x
set -e

echo "==> Compiling and installing virtualbox guest additions"
yum install -y bzip2 kernel-devel kernel-headers make gcc
mount -o loop /root/VBoxGuestAdditions.iso /mnt
sh /mnt/VBoxLinuxAdditions.run
yum history undo -y last
