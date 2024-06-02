#!/bin/sh

# Install k3s for worker
curl -sfL https://get.k3s.io | K3S_URL="https://192.168.56.110:6443" K3S_TOKEN=$(cat /vagrant/scripts/token) sh -s - agent --flannel-iface="eth1"
