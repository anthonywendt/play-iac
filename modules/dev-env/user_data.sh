#!/bin/bash
sudo apt-get update
sudo apt-get install -y docker.io
sudo systemctl enable docker
sudo systemctl start docker
sudo usermod -aG docker ubuntu
echo "export KUBECONFIG=/home/ubuntu/cluster-kubeconfig.yaml" | sudo tee -a /home/ubuntu/.bashrc
echo "export GPG_TTY=\$(tty)" | sudo tee -a /home/ubuntu/.bashrc
echo "alias k=\"kubectl\"" | sudo tee -a /home/ubuntu/.bashrc
echo "alias kmtsi-test=\"export KUBECONFIG=/home/ubuntu/mtsi-test\"" | sudo tee -a /home/ubuntu/.bashrc
echo "alias kmtsi-dev=\"export KUBECONFIG=/home/ubuntu/mtsi-dev\"" | sudo tee -a /home/ubuntu/.bashrc
echo "alias k-default=\"export KUBECONFIG=/home/ubuntu/cluster-kubeconfig.yaml\"" | sudo tee -a /home/ubuntu/.bashrc
sudo apt install -y jq git make wget sslscan
sudo sysctl -w vm.max_map_count=262144
sudo ulimit -n 65536
sudo echo "PubkeyAcceptedKeyTypes=+ssh-rsa" >> /etc/ssh/sshd_config
sudo service ssh reload
sudo sysctl fs.inotify.max_user_instances=512
sudo sysctl -p
sudo snap install go --channel=1.21/stable --classic
sudo curl -sL https://github.com/defenseunicorns/zarf/releases/download/v0.32.5/zarf_v0.32.5_Linux_amd64 -o /usr/local/bin/zarf
sudo chmod +x /usr/local/bin/zarf
sudo curl -sL https://github.com/defenseunicorns/uds-cli/releases/download/v0.9.4/uds-cli_v0.9.4_Linux_amd64 -o /usr/local/bin/uds && sudo chmod +x /usr/local/bin/uds
sudo chmod +x /usr/local/bin/uds
newgrp docker <<EONG
curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
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
nodes:
- role: control-plane
  kubeadmConfigPatches:
  - |
    kind: InitConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        max-pods: "200"
EOF
KUBECONFIG=/home/ubuntu/cluster-kubeconfig.yaml
# kind create cluster --image kindest/node:v1.26.3 --config /home/ubuntu/kind-config.yaml --name kind-cluster --kubeconfig \$KUBECONFIG
sudo chown ubuntu:ubuntu \$KUBECONFIG
sudo curl -s https://fluxcd.io/install.sh | sudo FLUX_VERSION=2.1.1 bash
EONG
