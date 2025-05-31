#!/bin/sh

echo "Installing docker and it's dependencies..."
apt-get update >/dev/null
apt-get install ca-certificates curl >/dev/null
install -m 0755 -d /etc/apt/keyrings >/dev/null
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc >/dev/null
chmod a+r /etc/apt/keyrings/docker.asc >/dev/null
echo \
	"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" |
	tee /etc/apt/sources.list.d/docker.list >/dev/null
apt-get update >/dev/null
apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y >/dev/null

echo "Installing k3d..."
wget -q -O - https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash >/dev/null

# Install kubectl
echo "Installing kubectl..."
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" >/dev/null 2>&1
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl.sha256" >/dev/null 2>&1
echo "$(cat kubectl.sha256)  kubectl" | sha256sum -c >/dev/null
install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl >/dev/null

# Setup cluster
echo "Creating the main cluster..."
k3d cluster create main >/dev/null

echo "Creating argocd namespace..."
kubectl create ns argocd >/dev/null

echo "Creating dev namespace..."
kubectl create ns dev >/dev/null

echo "Applying the argocd yaml file..."
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml >/dev/null

# Install ArgoCD CLI
echo "Installing argocd CLI..."
curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64 >/dev/null
install -m 555 argocd-linux-amd64 /usr/local/bin/argocd >/dev/null
rm argocd-linux-amd64 >/dev/null

echo "Waiting for Argo CD server pod to be ready..."
kubectl wait --for=condition=available --timeout=180s deployment/argocd-server -n argocd

echo "Port forward the argocd to https://0.0.0.0:8080..."
nohup kubectl port-forward --address 0.0.0.0 svc/argocd-server -n argocd 8080:443 >/home/vagrant/argocd-port-forward.log 2>&1 &

echo "Login into argocd..."
argocd login localhost:8080 --username admin --password "$(
	kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
	echo
)" --insecure >/dev/null

echo "Set the current kubectl context to argocd..."
kubectl config set-context --current --namespace=argocd >/dev/null

echo "Create the wils-app using argocd CLI..."
argocd app create wils-app --repo https://github.com/IssaMDOunejjaR/inception_of_things --path "./p3/confs/" --dest-server https://kubernetes.default.svc --dest-namespace dev --sync-policy automated >/dev/null

echo "Export argocd admin password..."
argocd admin initial-password >/vagrant/confs/password
