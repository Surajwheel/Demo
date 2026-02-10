#!/bin/bash

# ============================================================================
# AWS EC2 PREREQUISITES INSTALLATION SCRIPT
# Complete setup for k3d Kubernetes on AWS
# ============================================================================
# This script installs all prerequisites needed to run k3d on AWS EC2
# Run this as root or with sudo

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
print_header() {
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║ $1${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_info() {
    echo -e "${YELLOW}ℹ${NC} $1"
}

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   print_error "This script must be run as root"
   echo "Run: sudo bash prerequisites.sh"
   exit 1
fi

print_header "AWS EC2 PREREQUISITES INSTALLATION"

# ============================================================================
# STEP 1: System Updates
# ============================================================================
print_info "Step 1: Updating system packages..."
apt-get update
apt-get upgrade -y
print_success "System packages updated"

# ============================================================================
# STEP 2: Install Docker
# ============================================================================
print_info "Step 2: Installing Docker..."

# Remove old Docker versions
apt-get remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true

# Install Docker dependencies
apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    software-properties-common

# Add Docker GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Add Docker repository
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Start Docker
systemctl start docker
systemctl enable docker

# Verify Docker
docker --version
print_success "Docker installed and started"

# ============================================================================
# STEP 3: Add current user to docker group (for non-root access)
# ============================================================================
print_info "Step 3: Configuring Docker for non-root access..."

# Create docker group if it doesn't exist
groupadd -f docker

# Add ubuntu user (default AWS user) to docker group
usermod -aG docker ubuntu 2>/dev/null || true

# Also add any user running this script
if [ ! -z "$SUDO_USER" ]; then
    usermod -aG docker $SUDO_USER
    print_success "Added $SUDO_USER to docker group"
fi

print_info "Note: User needs to log out and log back in for group changes to take effect"

# ============================================================================
# STEP 4: Install kubectl
# ============================================================================
print_info "Step 4: Installing kubectl..."

# Download kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"

# Install kubectl
install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
rm kubectl

# Verify kubectl
kubectl version --client
print_success "kubectl installed"

# ============================================================================
# STEP 5: Install k3d
# ============================================================================
print_info "Step 5: Installing k3d..."

# Download and install k3d
curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash

# Verify k3d
k3d version
print_success "k3d installed"

# ============================================================================
# STEP 6: Install Helm
# ============================================================================
print_info "Step 6: Installing Helm..."

# Download Helm installation script
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Verify Helm
helm version
print_success "Helm installed"

# ============================================================================
# STEP 7: Install additional tools
# ============================================================================
print_info "Step 7: Installing additional tools..."

# Install jq for JSON processing
apt-get install -y jq

# Install git
apt-get install -y git

# Install wget
apt-get install -y wget

# Install nano/vim
apt-get install -y nano vim

# Install net-tools
apt-get install -y net-tools

# Install zip/unzip
apt-get install -y zip unzip

print_success "Additional tools installed"

# ============================================================================
# STEP 8: Configure Docker daemon for k3d
# ============================================================================
print_info "Step 8: Configuring Docker daemon..."

# Create docker daemon config directory
mkdir -p /etc/docker

# Create/Update docker daemon configuration
cat > /etc/docker/daemon.json << 'EOF'
{
  "debug": false,
  "storage-driver": "overlay2",
  "storage-opts": [
    "overlay2.override_kernel_check=true"
  ],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "insecure-registries": [],
  "registry-mirrors": []
}
EOF

# Restart Docker to apply configuration
systemctl restart docker
print_success "Docker daemon configured"

# ============================================================================
# STEP 9: Verify system resources
# ============================================================================
print_info "Step 9: Verifying system resources..."

# Get CPU count
CPU_COUNT=$(nproc)
echo "Available CPUs: $CPU_COUNT"

# Get memory
MEMORY_GB=$(free -g | awk '/^Mem:/{print $2}')
echo "Available Memory: ${MEMORY_GB}GB"

# Get disk space
DISK_GB=$(df -BG / | awk 'NR==2 {print $4}' | sed 's/G//')
echo "Available Disk Space: ${DISK_GB}GB"

# Check requirements
if [ "$CPU_COUNT" -lt 2 ]; then
    print_error "Warning: Less than 2 CPUs detected. Recommend at least 2 CPUs"
fi

if [ "$MEMORY_GB" -lt 4 ]; then
    print_error "Warning: Less than 4GB RAM detected. Recommend at least 8GB RAM"
fi

if [ "$DISK_GB" -lt 20 ]; then
    print_error "Warning: Less than 20GB disk space. Recommend at least 50GB"
fi

print_success "System verification complete"

# ============================================================================
# STEP 10: Create work directory
# ============================================================================
print_info "Step 10: Creating work directory..."

mkdir -p /home/ubuntu/k3d-microservices
cd /home/ubuntu/k3d-microservices

# Create subdirectories
mkdir -p k8s/{storage,databases,microservices,monitoring}
mkdir -p scripts
mkdir -p docs
mkdir -p backups

chown -R ubuntu:ubuntu /home/ubuntu/k3d-microservices

print_success "Work directory created at /home/ubuntu/k3d-microservices"

# ============================================================================
# STEP 11: Create kubeconfig directory
# ============================================================================
print_info "Step 11: Setting up kubeconfig..."

mkdir -p /home/ubuntu/.kube
touch /home/ubuntu/.kube/config
chown -R ubuntu:ubuntu /home/ubuntu/.kube
chmod 700 /home/ubuntu/.kube
chmod 600 /home/ubuntu/.kube/config

print_success "Kubeconfig directory created"

# ============================================================================
# FINAL SUMMARY
# ============================================================================
print_header "INSTALLATION COMPLETE!"

echo ""
echo -e "${GREEN}✓ All prerequisites installed successfully!${NC}"
echo ""
echo "Installed components:"
echo "  ✓ Docker $(docker --version | awk '{print $3}')"
echo "  ✓ kubectl $(kubectl version --client --short | awk '{print $3}')"
echo "  ✓ k3d $(k3d version | grep k3d | awk '{print $3}')"
echo "  ✓ Helm $(helm version --short | awk '{print $2}')"
echo "  ✓ Additional tools (jq, git, wget, net-tools, etc.)"
echo ""
echo "System Resources:"
echo "  ✓ CPUs: $CPU_COUNT"
echo "  ✓ Memory: ${MEMORY_GB}GB"
echo "  ✓ Disk: ${DISK_GB}GB"
echo ""
echo "Next steps:"
echo "  1. Log out and log back in for docker group changes"
echo "  2. cd /home/ubuntu/k3d-microservices"
echo "  3. Run: ./setup-k3d-cluster.sh"
echo ""
echo "Recommended EC2 instance type:"
echo "  • For development: t3.large (2 CPUs, 8GB RAM)"
echo "  • For production: t3.xlarge (4 CPUs, 16GB RAM)"
echo ""
echo "Work directory: /home/ubuntu/k3d-microservices"
echo ""

print_success "Ready to create k3d cluster!"

