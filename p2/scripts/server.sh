#! /bin/sh

echo "Installing k3s with server mode..."
curl -sfL https://get.k3s.io | sh -s - server --write-kubeconfig-mode="644" --flannel-iface="eth1" > /dev/null

echo "Waiting for k3s to be ready..."
until kubectl get nodes 2> /dev/null | grep -w "Ready" > /dev/null 2>&1; do
  sleep 1
done

echo "Applying Kubernetes YAML files..."
kubectl apply -f /vagrant/confs/app_one.yml > /dev/null
kubectl apply -f /vagrant/confs/app_two.yml > /dev/null
kubectl apply -f /vagrant/confs/app_three.yml > /dev/null
kubectl apply -f /vagrant/confs/ingress.yml > /dev/null
