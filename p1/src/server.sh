#! /bin/sh

# Check and update the packages
yum check-update
yum update -y

# Install k3s
curl -sfL https://get.k3s.io | sh -s - server --write-kubeconfig-mode="644" --flannel-iface="eth1"