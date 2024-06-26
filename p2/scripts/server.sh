#! /bin/sh

# Install k3s
curl -sfL https://get.k3s.io | sh -s - server --write-kubeconfig-mode="644" --flannel-iface="eth1"

echo "Waiting for k3s to run..."
# until [ -f /var/lib/rancher/k3s/server/token ]; do
# 	sleep 1
# done
sleep 30

# Apply deployments
kubectl apply -f /vagrant/confs/app_one.yml
kubectl apply -f /vagrant/confs/app_two.yml
kubectl apply -f /vagrant/confs/app_three.yml
kubectl apply -f /vagrant/confs/ingress.yml
