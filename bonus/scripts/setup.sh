#!/bin/sh

apk add --update docker git

service docker start

# Install K3d
wget -q -O - https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash

# Install Kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl.sha256"
echo "$(cat kubectl.sha256)  kubectl" | sha256sum -c
install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Install Helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Setup cluster
k3d cluster create main

mkdir ~/.kube

k3d kubeconfig get main >~/.kube/config.yml

export KUBECONFIG="$HOME/.kube/config.yml"

# Install Gitlab
kubectl create ns gitlab
helm repo add gitlab https://charts.gitlab.io/
helm repo update
helm upgrade --install gitlab gitlab/gitlab \
	--timeout 600s \
	--set global.hosts.domain=ounejjar.com \
	--set global.hosts.externalIP=192.168.56.200 \
	--set certmanager-issuer.email=me@example.com \
	--set postgresql.image.tag=13.6.0 \
	--set global.edition=ce -n gitlab

kubectl port-forward --address 0.0.0.0 svc/gitlab-nginx-ingress-controller -n gitlab 443:433 </dev/null &>/dev/null &

kubectl get secret gitlab-gitlab-initial-root-password -n gitlab -ojsonpath='{.data.password}' | base64 -d > /vagrant/confs/gitlab-password

# Install ArgoCD
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

# argocd app create wils-app --repo https://github.com/IssaMDOunejjaR/inception_of_things --path "./p3/confs/" --dest-server https://kubernetes.default.svc --dest-namespace dev --sync-policy automated

argocd admin initial-password >/vagrant/confs/argocd-password
