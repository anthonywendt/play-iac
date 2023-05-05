#!/bin/bash
sudo apt-get update
sudo apt-get install -y docker.io
sudo systemctl enable docker
sudo systemctl start docker
sudo usermod -aG docker ubuntu
echo "export KUBECONFIG=/home/ubuntu/kind-cluster-kubeconfig.yaml" | sudo tee -a /home/ubuntu/.bashrc
sudo apt install -y jq git make wget sslscan
sudo sysctl -w vm.max_map_count=262144
sudo ulimit -n 65536
sudo echo "PubkeyAcceptedKeyTypes=+ssh-rsa" >> /etc/ssh/sshd_config
sudo service ssh reload
sudo sysctl fs.inotify.max_user_instances=512
sudo sysctl -p
newgrp docker <<EONG
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.17.0/kind-linux-amd64
chmod +x ./kind
sudo mv kind /usr/local/bin/
curl --silent --location "https://storage.googleapis.com/kubernetes-release/release/$(curl --silent https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl" -o /tmp/kubectl
chmod +x /tmp/kubectl
sudo mv /tmp/kubectl /usr/local/bin/
cat << EOF > /home/ubuntu/kind-config.yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
networking:
  apiServerPort: 6443
EOF
KUBECONFIG=/home/ubuntu/kind-cluster-kubeconfig.yaml
kind create cluster --image kindest/node:v1.26.3 --config /home/ubuntu/kind-config.yaml --name kind-cluster --kubeconfig \$KUBECONFIG
sudo chown ubuntu:ubuntu \$KUBECONFIG
export FLUX_VERSION=0.41.1
curl -s https://fluxcd.io/install.sh | sudo bash
EONG
