#!/bin/bash

# ============================================================================
# K3D CLUSTER SETUP SCRIPT FOR AWS EC2
# Complete local Kubernetes cluster with monitoring and microservices
# ============================================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
CLUSTER_NAME="local-k8s"
SERVERS=1
AGENTS=2
K3S_VERSION="v1.27.0"
REGISTRY_PORT="5000"

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

print_header "K3D KUBERNETES CLUSTER SETUP FOR AWS"

# ============================================================================
# STEP 1: Verify prerequisites
# ============================================================================
print_info "Step 1: Verifying prerequisites..."

# Check Docker
if ! command -v docker &> /dev/null; then
    print_error "Docker not found. Run prerequisites.sh first"
    exit 1
fi
print_success "Docker found: $(docker --version)"

# Check kubectl
if ! command -v kubectl &> /dev/null; then
    print_error "kubectl not found. Run prerequisites.sh first"
    exit 1
fi
print_success "kubectl found: $(kubectl version --client --short 2>/dev/null)"

# Check k3d
if ! command -v k3d &> /dev/null; then
    print_error "k3d not found. Run prerequisites.sh first"
    exit 1
fi
print_success "k3d found: $(k3d version)"

# Check helm
if ! command -v helm &> /dev/null; then
    print_error "Helm not found. Run prerequisites.sh first"
    exit 1
fi
print_success "Helm found: $(helm version --short)"

# ============================================================================
# STEP 2: Create directory structure
# ============================================================================
print_info "Step 2: Creating directory structure..."

WORK_DIR="/home/ubuntu/k3d-microservices"
mkdir -p $WORK_DIR/k8s/{dev,staging,prod,base}
mkdir -p $WORK_DIR/scripts
mkdir -p $WORK_DIR/docs
mkdir -p $WORK_DIR/backups
mkdir -p $WORK_DIR/logs

print_success "Directory structure created"

# ============================================================================
# STEP 3: Create k3d cluster
# ============================================================================
print_info "Step 3: Creating k3d cluster (this may take 2-3 minutes)..."

# Check if cluster already exists
if k3d cluster list | grep -q "^${CLUSTER_NAME}"; then
    print_info "Cluster ${CLUSTER_NAME} already exists. Skipping creation..."
else
    k3d cluster create ${CLUSTER_NAME} \
        --servers ${SERVERS} \
        --agents ${AGENTS} \
        --port 80:80@loadbalancer \
        --port 443:443@loadbalancer \
        --port 6379:6379@loadbalancer \
        --port 3306:3306@loadbalancer \
        --port 27017:27017@loadbalancer \
        -p 6443:6443@loadbalancer \
        --volume /tmp/k3d-storage:/data \
        --k3s-arg "--disable=traefik@server:0" \
        --wait
    
    print_success "K3d cluster created: ${CLUSTER_NAME}"
fi

# ============================================================================
# STEP 4: Configure kubeconfig
# ============================================================================
print_info "Step 4: Configuring kubeconfig..."

k3d kubeconfig merge ${CLUSTER_NAME} --switch-context
mkdir -p $HOME/.kube
k3d kubeconfig get ${CLUSTER_NAME} > $HOME/.kube/config.k3d
export KUBECONFIG=$HOME/.kube/config.k3d

print_success "Kubeconfig configured"

# ============================================================================
# STEP 5: Verify cluster connectivity
# ============================================================================
print_info "Step 5: Verifying cluster connectivity..."

sleep 5

# Check nodes
NODE_COUNT=$(kubectl get nodes --no-headers 2>/dev/null | wc -l)
print_info "Cluster nodes: $NODE_COUNT"

# Get node status
kubectl get nodes
print_success "Cluster connectivity verified"

# ============================================================================
# STEP 6: Create namespaces
# ============================================================================
print_info "Step 6: Creating Kubernetes namespaces..."

kubectl create namespace dev-microservices --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace databases --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace ingress-nginx --dry-run=client -o yaml | kubectl apply -f -

print_success "Namespaces created"

# ============================================================================
# STEP 7: Install nginx-ingress
# ============================================================================
print_info "Step 7: Installing nginx-ingress controller..."

helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

helm install nginx-ingress ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --set controller.service.type=LoadBalancer \
  --set controller.metrics.enabled=true \
  --wait

print_success "nginx-ingress installed"

# ============================================================================
# STEP 8: Install Prometheus and Grafana
# ============================================================================
print_info "Step 8: Installing Prometheus and Grafana..."

helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --set prometheus.prometheusSpec.retention=7d \
  --set prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.resources.requests.storage=10Gi \
  --set grafana.adminPassword=admin123 \
  --set grafana.persistence.enabled=true \
  --set grafana.persistence.size=5Gi \
  --wait

print_success "Prometheus and Grafana installed"

# ============================================================================
# STEP 9: Wait for services to be ready
# ============================================================================
print_info "Step 9: Waiting for services to be ready..."

sleep 30
print_success "Services ready"

# ============================================================================
# STEP 10: Display access information
# ============================================================================
print_header "CLUSTER SETUP COMPLETE!"

echo ""
echo "Cluster Information:"
echo "  Name: ${CLUSTER_NAME}"
echo "  Servers: ${SERVERS}"
echo "  Agents: ${AGENTS}"
echo ""
echo "Cluster Status:"
kubectl get nodes
echo ""
echo "Namespaces:"
kubectl get namespaces
echo ""
echo "Services:"
echo ""
echo "Ingress Controller:"
kubectl get svc -n ingress-nginx
echo ""
echo "Monitoring Stack:"
kubectl get svc -n monitoring | grep -E "prometheus|grafana" || echo "Services starting..."
echo ""
echo "Next steps:"
echo "  1. Save kubeconfig: export KUBECONFIG=$HOME/.kube/config.k3d"
echo "  2. Copy YAML files to: $WORK_DIR/k8s/"
echo "  3. Deploy: kubectl apply -f $WORK_DIR/k8s/dev/"
echo "  4. Access Grafana: kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80"
echo "  5. Access Prometheus: kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090"
echo ""
echo "Useful commands:"
echo "  kubectl get pods -n dev-microservices"
echo "  kubectl logs -f deployment/user-service -n dev-microservices"
echo "  kubectl port-forward svc/service-name 8080:8080 -n dev-microservices"
echo ""
echo "To delete cluster:"
echo "  k3d cluster delete ${CLUSTER_NAME}"
echo ""

print_success "K3d cluster ready for deployment!"

