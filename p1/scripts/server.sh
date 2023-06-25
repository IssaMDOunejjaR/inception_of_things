#! /bin/sh

# Install k3s
curl -sfL https://get.k3s.io | sh -s - server --write-kubeconfig-mode="644" --flannel-iface="eth1"

until [ -f /var/lib/rancher/k3s/server/token ]
do
	sleep 1
done

cat /var/lib/rancher/k3s/server/token > /vagrant/scripts/token