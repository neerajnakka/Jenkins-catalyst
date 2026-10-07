#!/usr/bin/env bash
# =============================================================
#  jenkins/ec2-install.sh -- Block 1
#  Fresh Ubuntu 24.04 LTS EC2  ->  Jenkins LTS + Docker engine
#  Usage:  bash ec2-install.sh
# =============================================================
set -euo pipefail

echo "### 1/7  Base packages + system update"
sudo apt-get update -y && sudo apt-get upgrade -y
sudo apt-get install -y fontconfig ca-certificates curl gnupg git unzip jq

echo "### 2/7  Java 21  (Jenkins LTS 2.4xx supports Java 17 and 21)"
sudo apt-get install -y openjdk-21-jre-headless
java -version

echo "### 3/7  Official Jenkins apt repository (keyring style, not apt-key)"
sudo install -d -m 0755 /etc/apt/keyrings
sudo curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key \
     -o /etc/apt/keyrings/jenkins-keyring.asc
echo "deb [signed-by=/etc/apt/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" \
  | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null
sudo apt-get update -y

echo "### 4/7  Install Jenkins LTS and enable it at boot"
sudo apt-get install -y jenkins
sudo systemctl enable --now jenkins
sleep 25
sudo systemctl status jenkins --no-pager | head -5

echo "### 5/7  Docker engine (needed from Block 9: build & push)"
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
  | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update -y
sudo apt-get install -y docker-ce docker-ce-cli containerd.io \
                        docker-buildx-plugin docker-compose-plugin

echo "### 6/7  Let the 'jenkins' user build docker images (LEARNING SHORTCUT - see doc)"
sudo usermod -aG docker jenkins
sudo tee /etc/sudoers.d/jenkins > /dev/null <<'SUDO'
jenkins ALL=(ALL) NOPASSWD:ALL
SUDO
sudo chmod 0440 /etc/sudoers.d/jenkins

echo "### 7/7  Restart so the new group membership is picked up"
sudo systemctl restart docker
sudo systemctl restart jenkins
sleep 20
echo "=========================================================="
echo " Unlock password  ->  paste this in the browser:"
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
echo "=========================================================="
echo " Open:  http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):8080"
