#!/bin/sh

echo "Installing k3s with server mode..."
curl -sfL https://get.k3s.io | sh -s - server --write-kubeconfig-mode="644" --flannel-iface="eth1" > /dev/null

echo "Waiting for k3s to create the token..."
until [ -f /var/lib/rancher/k3s/server/token ]; do
	sleep 1
done

echo "Export the token..."
cat /var/lib/rancher/k3s/server/agent-token >/vagrant/scripts/token
