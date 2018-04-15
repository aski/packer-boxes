#!/usr/bin/env bash

set -x
set -e

date > /etc/vagrant_box_build_time

echo "==> Create vagrant user and groups"
groupadd vagrant
useradd vagrant -g vagrant -G wheel
echo "vagrant" | passwd --stdin vagrant

echo "==> Configure sudo permissions for vagrant"
echo "%vagrant        ALL=(ALL)       NOPASSWD: ALL" >> /etc/sudoers.d/vagrant
chmod 0440 /etc/sudoers.d/vagrant

echo "==> Add default vagrant public key to authorized_keys file"
mkdir -pm 700 /home/vagrant/.ssh
curl \
 --output /home/vagrant/.ssh/authorized_keys \
 --create-dirs \
 --location https://raw.github.com/mitchellh/vagrant/master/keys/vagrant.pub
chmod 0600 /home/vagrant/.ssh/authorized_keys
chown -R vagrant /home/vagrant/.ssh
