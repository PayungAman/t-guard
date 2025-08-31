#!/bin/bash
# Automated T-Guard installation script
# This script automatically runs steps 1-6 from setup.sh without user interaction

echo "Starting automated T-Guard installation..."

# Step 1: Update System and Install Prerequisites
echo "Step 1: Updating system and installing prerequisites..."
sudo apt-get update -y
sudo apt-get upgrade -y
sudo apt-get install wget curl nano git unzip nodejs whiptail -y
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update

# Step 2: Install Docker (already done in Vagrantfile provisioning)
echo "Step 2: Verifying Docker installation..."
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Step 3: Install Wazuh (SIEM) & Deploy Agent
echo "Step 3: Installing Wazuh (SIEM) & deploying agent..."
cd /vagrant/wazuh
sudo docker network create shared-network
sudo docker compose -f generate-indexer-certs.yml run --rm generator
sudo docker compose up -d

# Wait for Wazuh containers to be ready
echo "Waiting for Wazuh containers to start..."
sleep 30

# Check Wazuh Status
containers=(
    "wazuh-wazuh.dashboard-1"
    "wazuh-wazuh.manager-1"
    "wazuh-wazuh.indexer-1"
)

for container in "${containers[@]}"; do
    running_status=$(sudo docker inspect --format='{{.State.Running}}' $container 2>/dev/null)
    if [ "$running_status" != "true" ]; then
        echo "Warning: $container is not running."
    else
        echo "$container is running."
    fi
done

# Deploy Wazuh Agent automatically
echo "Deploying Wazuh Agent..."
wazuh_manager="127.0.0.1"  # Local installation
agent_name="t-guard-agent"
wazuh_version=$(sudo docker images --format '{{.Repository}}:{{.Tag}}' | grep '^wazuh/wazuh-dashboard:' | cut -d':' -f2)

if [ -z "$wazuh_version" ]; then
    # If version detection fails, use a default version
    wazuh_version="4.5.1"
    echo "Could not detect Wazuh version, using default: $wazuh_version"
fi

wget https://packages.wazuh.com/4.x/apt/pool/main/w/wazuh-agent/wazuh-agent_${wazuh_version}-1_amd64.deb \
&& sudo WAZUH_MANAGER="$wazuh_manager" WAZUH_AGENT_NAME="$agent_name" dpkg -i ./wazuh-agent_${wazuh_version}-1_amd64.deb
sudo systemctl daemon-reload
sudo systemctl enable wazuh-agent
sudo systemctl start wazuh-agent

# Step 4: Install Shuffle (SOAR)
echo "Step 4: Installing Shuffle (SOAR)..."
cd /vagrant/shuffle
mkdir -p shuffle-database 
sudo chown -R 1000:1000 shuffle-database
sudo swapoff -a
sudo docker compose up -d

# Step 5: Install DFIR-IRIS (Incident Response Platform)
echo "Step 5: Installing DFIR-IRIS (Incident Response Platform)..."
cd /vagrant/iris-web
sudo docker compose build
sudo docker compose up -d

# Step 6: Install MISP (Threat Intelligence)
echo "Step 6: Installing MISP (Threat Intelligence)..."
cd /vagrant/misp

# Configure with private IP
IP=$(hostname -I | awk '{print $1}')
sed -i "s|BASE_URL=.*|BASE_URL='https://$IP:1443'|" template.env
cp template.env .env
sudo docker compose up -d

echo "T-Guard automated installation complete!"
echo "You can access the following services:"
echo "- Wazuh: https://$IP (username: admin, password: admin)"
echo "- Shuffle: http://$IP:3001"
echo "- DFIR-IRIS: http://$IP:8000 (username: administrator, password: administrator)"
echo "- MISP: https://$IP:1443 (username: admin@admin.test, password: admin)"
echo ""
echo "For further configuration or to run the integration steps (7-10), use the setup.sh script."
