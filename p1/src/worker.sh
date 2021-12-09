#! /bin/sh

# Check and update the packages
yum check-update
yum update -y

# Install k3s for worker
# curl -sfL https://get.k3s.io | K3S_URL="https://192.168.42.110:6443" K3S_TOKEN="K105b06b4b74b0fd92196c5267567cb87c1d24eb51716ddd1b363919b008665b8be::server:8800a552731b0af0ba6bc3d8bd576306" sh -s - agent --flannel-iface="eth1"