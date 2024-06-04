#!/bin/sh

apk add --update docker

service docker start

# Install k3d
wget -q -O - https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash

# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl.sha256"
echo "$(cat kubectl.sha256)  kubectl" | sha256sum -c
install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Setup cluster
k3d cluster create main
kubectl create ns argocd
kubectl create ns dev
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Install ArgoCD CLI
curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
rm argocd-linux-amd64

# Wait for ArgoCD CLI to run
sleep 60

kubectl port-forward --address 0.0.0.0 svc/argocd-server -n argocd 8080:443 </dev/null &>/dev/null &

argocd login localhost:8080 --username admin --password $(
	kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
	echo
) --insecure

kubectl config set-context --current --namespace=argocd

argocd app create wils-app --repo https://github.com/IssaMDOunejjaR/inception_of_things --path "./p3/confs/" --dest-server https://kubernetes.default.svc --dest-namespace dev --sync-policy automated

argocd admin initial-password >/vagrant/confs/password
