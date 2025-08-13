#!/bin/bash

# =============================================================================
# CapRover WSL Installation Script (Linux Guest)
# Version 1.0
# =============================================================================
# This script performs the final, manual installation of CapRover. It is
# designed to be called by the Windows batch script.
#
# This specific sequence is required to work around several bugs and race
# conditions present when installing CapRover in a WSL environment:
# 1. Manually creates the swarm to avoid installer conflicts.
# 2. Manually creates the /captain directory on the host to avoid a bug where
#    CapRover creates child services with invalid mount paths.
# 3. Uses IS_CAPTAIN_INSTANCE=true flag to force the container to run as the
#    application, not the installer.
# 4. Uses BY_PASS_PROXY_CHECK=true to avoid network self-test failures
#    common in WSL/NAT environments.
# 5. Applies network aliases to the captain-nginx service to fix the internal
#    health check crash loop.
# =============================================================================

# Exit immediately if a command exits with a non-zero status.
set -e

# Define some colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Starting CapRover setup inside WSL...${NC}"
echo

# --- Prompt for User Input ---
read -p "Please enter your server's public IP address: " PUBLIC_IP
read -p "Please enter your CapRover root domain (e.g., data.mydomain.com): " ROOT_DOMAIN

if ! [[ $PUBLIC_IP =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo -e "${YELLOW}ERROR: Invalid IP address format. Exiting.${NC}"
    exit 1
fi

echo -e "${GREEN}Using Public IP: $PUBLIC_IP${NC}"
echo -e "${GREEN}Using Root Domain: $ROOT_DOMAIN${NC}"
echo

# --- Step 1: Full and Complete Cleanup ---
echo -e "${GREEN}Performing full cleanup of any previous CapRover installation...${NC}"
# The '|| true' prevents the script from failing if the resources don't exist
docker service rm captain-captain captain-nginx captain-certbot >/dev/null 2>&1 || true
docker secret rm captain-salt >/dev/null 2>&1 || true
docker swarm leave --force >/dev/null 2>&1 || true
sudo rm -rf /captain
echo "Cleanup complete."
echo

# --- Step 1.5: Prepare Host DNS ---
echo -e "${GREEN}Preparing host DNS...${NC}"
cat > /etc/docker/daemon.json <<EOF
{
  "dns": ["1.1.1.1", "1.0.0.1"]
}
EOF

# Restart the Docker Daemon: After saving the changes, restart the Docker daemon for them to take effect: 
sudo systemctl restart docker

# --- Step 2: Prepare Host Environment ---
echo -e "${GREEN}Preparing Docker Swarm and required directories...${NC}"
docker swarm init --advertise-addr "$PUBLIC_IP"
# This directory MUST be /captain at the root due to a bug in how CapRover
# creates its child services (nginx, certbot).
sudo mkdir -p /captain
echo "Environment prepared."
echo

# --- Step 3: Deploy Main Service and Patch Nginx ---
echo -e "${GREEN}Deploying the main CapRover application service...${NC}"
docker service create \
  --name captain-captain \
  --mount type=bind,source=/captain,destination=/captain \
  --mount type=bind,source=/var/run/docker.sock,destination=/var/run/docker.sock \
  -p 3000:3000 \
  --constraint node.role==manager \
  -e ACCEPTED_TERMS=true \
  -e MAIN_NODE_IP_ADDRESS="$PUBLIC_IP" \
  -e CAPROVER_DISABLE_ANALYTICS=true \
  -e BY_PASS_PROXY_CHECK='TRUE' \
  -e IS_CAPTAIN_INSTANCE='true' \
  caprover/caprover:1.14.0

echo "Main service created. Waiting for Nginx service to appear..."
while ! docker service inspect captain-nginx >/dev/null 2>&1; do
    sleep 1
done
while ! docker network inspect captain-overlay-network >/dev/null 2>&1; do
    sleep 1
done

echo "Nginx service found! Applying network alias patch to fix health checks..."

# Disconnect and reconnect the service to the network to add the required aliases.
docker network disconnect captain-overlay-network captain-nginx
docker network connect \
  --alias "captain.$ROOT_DOMAIN" \
  --alias "$ROOT_DOMAIN" \
  captain-overlay-network captain-nginx
echo "Patch applied. Waiting for services to stabilize..."
sleep 30

# --- Step 4: Final Verification ---
echo
echo -e "${GREEN}Verifying installation status...${NC}"

cid=$(docker ps | grep caprover/caprover: | awk '{print $1}')
if [ "$cid" != "" ]; then
    hcIP=$(docker exec $cid nslookup captain.${ROOT_DOMAIN} | grep ^Address: | tail -n 1 | awk '{print $2}')
    if [ "$hcIP" = "$PUBLIC_IP" ]; then
        echo "Health check IP resolves correctly to: $hcIP"
    else
        echo "Health check will fail.  Enabling temporary workaround!!!!"
        # If the DNS doesn't resolve to the external IP address or at least to the internal nginx address, the health check will fail
        cat >/captain/data/config-override.json <<EOF
json
{
  "skipVerifyingDomains": "true"
}
EOF
        docker service update captain-captain --force
    fi
else
    echo "Missing caprover container!"
fi
docker service ls
echo

echo -e "${GREEN}-------------------------------------------------------------------${NC}"
echo -e "${GREEN}SUCCESS! CapRover installation is complete.${NC}"
echo
echo -e "You can now access your CapRover dashboard at:"
echo -e "${YELLOW}http://$PUBLIC_IP:3000${NC}"
echo
echo -e "The default password is: ${YELLOW}captain42${NC}"
echo -e "${GREEN}-------------------------------------------------------------------${NC}"
echo
