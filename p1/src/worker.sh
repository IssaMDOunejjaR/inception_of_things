#! /bin/sh

# Check and update the packages
yum check-update
# yum update -y

# Install k3s for worker
curl -sfL https://get.k3s.io | K3S_URL="https://192.168.42.110:6443" K3S_TOKEN="K104460fd19513f25381ac2571538ae58b1fcd21f03297afda103ce330ca82ac00b::server:f92530039fb7a3855545c1da5665232c" sh -s - agent --flannel-iface="eth1"