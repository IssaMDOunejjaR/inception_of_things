#!/bin/sh

echo "Installing docker and it's dependencies..."
apt-get update >/dev/null
apt-get install ca-certificates curl >/dev/null
install -m 0755 -d /etc/apt/keyrings >/dev/null
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc >/dev/null
chmod a+r /etc/apt/keyrings/docker.asc >/dev/null
# Add the repository to Apt sources:
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

# Install Helm
echo "Installing Helm..."
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash >/dev/null

# Setup cluster
echo "Create the main cluster..."
# k3d cluster create main >/dev/null
k3d cluster create main -p "80:80@loadbalancer" -p "443:443@loadbalancer" >/dev/null

echo "Create kubeconfig file..."
# mkdir /home/vagrant/.kube
k3d kubeconfig get main >/vagrant/config.yml
sed -i -e 's/0.0.0.0/192.168.56.200/g' /vagrant/config.yml
# export KUBECONFIG="/home/vagrant/.kube/config.yml"

exit 0

# Install Gitlab
echo "Create gitlab namespace..."
kubectl create ns gitlab

echo "Installing gitlab using Helm..."
helm repo add gitlab https://charts.gitlab.io/ >/dev/null
helm repo update >/dev/null
helm install -f /vagrant/confs/values.yml -n gitlab gitlab/gitlab
# helm upgrade --install gitlab gitlab/gitlab \ 
#   --timeout 600s \
#   --set global.hosts.domain=gitlab.iounejja.com \
#   --set global.hosts.externalIP=192.168.56.200 \
#   --set global.ingress.enabled=false \
#   --set global.ingress.tls.enabled=false --set certmanager-issuer.email=me@iounejja.com --set certmanager.install=false --set nginx-ingress.enabled=false -n gitlab --create-namespace

# helm upgrade --install gitlab gitlab/gitlab \
# 	--timeout 600s \
# 	--set global.hosts.domain=iounejja.com \
# 	--set global.hosts.externalIP=192.168.56.200 \
# 	--set certmanager-issuer.email=me@iounejja.com \
# 	--set global.edition=ce -n gitlab >/dev/null
# --set postgresql.image.tag=17.5 \

# echo "Waiting for Gitlab Ingress Controller pod to be ready..."
# kubectl wait --for=condition=available --timeout=180s deployment/argocd-server -n argocd

# echo "Port forward the argocd to https://0.0.0.0:443..."
# nohup kubectl port-forward --address 0.0.0.0 svc/gitlab-nginx-ingress-controller -n gitlab 443:433 >/home/vagrant/gitlab-nginx-ingress-controller.log 2>&1 &
# sleep 5

echo "Export gitlab initial password..."
kubectl get secret gitlab-gitlab-initial-root-password -n gitlab -ojsonpath='{.data.password}' | base64 -d >/vagrant/confs/gitlab-password

# Install ArgoCD
echo "Creating argocd namespace..."
kubectl create ns argocd >/dev/null

echo "Creating dev namespace..."
kubectl create ns dev >/dev/null

echo "Applying the argocd yaml file..."
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml >/dev/null

# Install ArgoCD CLI
echo "Installing argocd CLI..."
curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64 >/dev/null
sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd >/dev/null
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

# argocd app create wils-app --repo https://github.com/IssaMDOunejjaR/inception_of_things --path "./p3/confs/" --dest-server https://kubernetes.default.svc --dest-namespace dev --sync-policy automated

echo "Export argocd admin password..."
argocd admin initial-password >/vagrant/confs/argocd-password

# kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.14.3/cert-manager.yaml
