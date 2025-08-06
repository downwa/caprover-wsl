#!/bin/bash

# =============================================================================
# CapRover WSL Installation Script (Linux Guest)
# =============================================================================
# This script performs the final, manual installation of CapRover.
# It is designed to be called by the Windows batch script.
#
# This specific sequence is required to work around several bugs and race
# conditions present when installing CapRover in a WSL environment:
# 1. Manually creates the swarm to avoid installer conflicts.
# 2. Manually creates the /captain directory to avoid a bug where the
#    installer creates services with invalid mount paths.
# 3. Uses the IS_CAPTAIN_INSTANCE=true flag to force the container to run
#    as the application, not the installer.
# 4. Uses BY_PASS_PROXY_CHECK=true to avoid network self-test failures
#    common in WSL/NAT environments.
# =============================================================================

# Exit immediately if a command exits with a non-zero status.
set -e

# Define some colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Starting CapRover setup inside WSL...${NC}"
echo

# --- Prompt for Public IP ---
read -p "Please enter your server's public IP address: " PUBLIC_IP

if ! [[ $PUBLIC_IP =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo -e "${YELLOW}ERROR: Invalid IP address format. Exiting.${NC}"
    exit 1
fi

echo -e "${GREEN}Using Public IP: $PUBLIC_IP${NC}"
echo

# --- Step 1: Full Cleanup ---
echo -e "${GREEN}Performing full cleanup of any previous CapRover installation...${NC}"
# The '|| true' prevents the script from failing if the services don't exist
docker service rm captain-captain captain-nginx captain-certbot >/dev/null 2>&1 || true
docker swarm leave --force >/dev/null 2>&1 || true
sudo rm -rf /captain
echo "Cleanup complete."
echo

# --- Step 2: Prepare Host Environment ---
echo -e "${GREEN}Preparing Docker Swarm and required directories...${NC}"
docker swarm init --advertise-addr "$PUBLIC_IP"
# This directory MUST be /captain at the root due to a bug in how CapRover
# creates its child services (nginx, certbot).
sudo mkdir -p /captain
echo "Environment prepared."
echo

# --- Step 3: Deploy CapRover Application Service ---
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

echo "Main service created. Waiting for services to stabilize..."
sleep 45 # Give time for nginx and certbot to be created and start

# --- Step 4: Final Verification ---
echo
echo -e "${GREEN}Verifying installation status...${NC}"
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
