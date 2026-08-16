#!/bin/bash
set -euxo pipefail

export DEBIAN_FRONTEND=noninteractive

apt-get update
apt-get install -y ca-certificates curl

install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

ARCHITECTURE="$(dpkg --print-architecture)"
CODENAME="$(. /etc/os-release && echo "$VERSION_CODENAME")"
echo "deb [arch=${ARCHITECTURE} signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu ${CODENAME} stable" \
  > /etc/apt/sources.list.d/docker.list

apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
systemctl enable --now docker

# Add ubuntu user to docker group
usermod -aG docker ubuntu

# Make docker socket accessible to docker group members
chmod 660 /var/run/docker.sock

# Allow ubuntu to use sudo with docker without password
echo 'ubuntu ALL=(ALL) NOPASSWD: /usr/bin/docker, /usr/bin/docker-compose, /usr/bin/docker compose' >> /etc/sudoers.d/docker

# Wait for docker to be ready
sleep 5
systemctl restart docker
sleep 3

install -d -o ubuntu -g ubuntu -m 0755 /home/ubuntu/dream-vacation
