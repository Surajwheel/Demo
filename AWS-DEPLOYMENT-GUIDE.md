# AWS EC2 K3D Kubernetes Deployment Guide

## Table of Contents
1. [Prerequisites](#prerequisites)
2. [AWS Account Setup](#aws-account-setup)
3. [Terraform Deployment](#terraform-deployment)
4. [EC2 Setup](#ec2-setup)
5. [Docker Installation](#docker-installation)
6. [K3D Cluster Creation](#k3d-cluster-creation)
7. [Kubernetes Deployment](#kubernetes-deployment)
8. [Verification & Testing](#verification--testing)
9. [Troubleshooting](#troubleshooting)
10. [Cleanup](#cleanup)

---

## Prerequisites

### Local Machine Requirements
- AWS CLI v2 or higher
- Terraform v1.0 or higher
- SSH client
- Terminal/Command line access

### AWS Account Requirements
- Active AWS account
- IAM user with EC2, VPC, and IAM permissions
- AWS credentials configured locally

---

## AWS Account Setup

### Step 1: Create AWS Account
```bash
# Go to https://aws.amazon.com/
# Click "Create an AWS Account"
# Follow the signup wizard
```

### Step 2: Create IAM User (Recommended)
```bash
# AWS Console → IAM → Users → Create user
# Attach policies:
#   - AmazonEC2FullAccess
#   - AmazonVPCFullAccess
#   - IAMFullAccess
```

### Step 3: Configure AWS CLI
```bash
# Install AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Or on macOS:
brew install awscli

# Configure credentials
aws configure
# Enter Access Key ID
# Enter Secret Access Key
# Enter region (e.g., us-east-1)
# Enter default output format (json)

# Verify configuration
aws sts get-caller-identity
```

### Step 4: Create EC2 Key Pair
```bash
# Via AWS Console:
# EC2 → Key Pairs → Create Key Pair
# - Name: k3d-microservices
# - Format: .pem (for Linux/Mac) or .ppk (for PuTTY)
# - Download and save securely

# Or via AWS CLI:
aws ec2 create-key-pair --key-name k3d-microservices \
  --region us-east-1 \
  --query 'KeyMaterial' \
  --output text > k3d-microservices.pem

chmod 400 k3d-microservices.pem
```

---

## Terraform Deployment

### Step 1: Download Terraform Configuration
```bash
# Create project directory
mkdir -p ~/k3d-aws-deployment
cd ~/k3d-aws-deployment

# Copy these files:
# - main.tf (Terraform configuration)
# - variables.tf (Variable definitions)
# - terraform.tfvars.example (Example values)
# - prerequisites.sh (Installation script)
# - user_data.sh (EC2 initialization)
# - setup-k3d-cluster.sh (K3D setup script)
```

### Step 2: Create terraform.tfvars
```bash
# Copy example to actual tfvars
cp terraform.tfvars.example terraform.tfvars

# Edit terraform.tfvars
nano terraform.tfvars

# Key changes:
# - aws_region = "us-east-1"  (or your region)
# - instance_type = "t3.large"
# - key_pair_name = "k3d-microservices"  (key pair name created above)
# - allowed_ssh_cidr = ["YOUR.IP.ADDRESS/32"]  (your IP for SSH)
```

### Step 3: Initialize Terraform
```bash
# Initialize Terraform
terraform init

# Validate configuration
terraform validate

# Format terraform files
terraform fmt -recursive
```

### Step 4: Plan Deployment
```bash
# Create plan
terraform plan -out=tfplan

# Review output to verify:
# - AWS region
# - Instance type
# - VPC and security group
# - Key pair name
```

### Step 5: Deploy Infrastructure
```bash
# Apply plan
terraform apply tfplan

# Wait for completion (2-3 minutes)
# Outputs will show:
# - instance_public_ip
# - instance_id
# - ssh_command
```

### Step 6: Save Outputs
```bash
# Save outputs for later reference
terraform output -json > outputs.json

# Get specific values
terraform output instance_public_ip
terraform output instance_id

# Note the public IP for SSH connection
```

---

## EC2 Setup

### Step 1: Connect to EC2 Instance
```bash
# Get instance IP from terraform output
INSTANCE_IP=$(terraform output -raw instance_public_ip)

# SSH into instance
ssh -i k3d-microservices.pem ubuntu@$INSTANCE_IP

# Or if using key pair name
ssh -i ~/path/to/k3d-microservices.pem ubuntu@<PUBLIC_IP>
```

### Step 2: Verify Initial Setup
```bash
# Check logs from user data script
tail -f /var/log/user-data.log

# The script has already created work directory
ls -la /home/ubuntu/k3d-microservices/
```

### Step 3: Update System (if needed)
```bash
# Update packages
sudo apt-get update
sudo apt-get upgrade -y

# Check available disk space
df -h

# Check memory
free -h

# Check CPU
nproc
```

---

## Docker Installation

### Step 1: Run Prerequisites Script
```bash
# The prerequisites script includes full Docker installation

# Run as sudo
sudo bash /home/ubuntu/k3d-microservices/scripts/prerequisites.sh

# This script will:
# ✓ Install Docker
# ✓ Install kubectl
# ✓ Install k3d
# ✓ Install Helm
# ✓ Install additional tools (jq, git, etc.)
# ✓ Configure Docker daemon
# ✓ Create work directories

# Wait for completion (5-10 minutes)
```

### Step 2: Verify Docker Installation
```bash
# Check Docker version
docker --version
# Should show: Docker version 24.x.x

# Test Docker without sudo
docker ps
# If permission denied, log out and log back in

# Run hello-world container
docker run hello-world
```

### Step 3: Add User to Docker Group (if needed)
```bash
# This might already be done by prerequisites.sh
# But if you get permission errors:

sudo usermod -aG docker ubuntu
sudo usermod -aG docker $USER

# Log out and log back in for changes to take effect
exit
ssh -i k3d-microservices.pem ubuntu@$INSTANCE_IP
```

### Step 4: Verify Other Tools
```bash
# Check kubectl
kubectl version --client

# Check k3d
k3d version

# Check Helm
helm version

# Check jq
jq --version

# Check git
git --version
```

---

## K3D Cluster Creation

### Step 1: Navigate to Work Directory
```bash
cd /home/ubuntu/k3d-microservices
```

### Step 2: Create K3D Cluster
```bash
# Method 1: Using provided setup script
bash scripts/setup-k3d-cluster.sh

# OR Method 2: Manual creation
k3d cluster create local-k8s \
  --servers 1 \
  --agents 2 \
  --port 80:80@loadbalancer \
  --port 443:443@loadbalancer \
  --volume /tmp/k3d-storage:/data \
  --wait

# Wait for cluster to be ready (2-3 minutes)
```

### Step 3: Configure kubeconfig
```bash
# Merge kubeconfig
k3d kubeconfig merge local-k8s --switch-context

# Verify kubeconfig location
echo $KUBECONFIG

# Set kubeconfig for current session
export KUBECONFIG=$HOME/.kube/config

# Add to .bashrc for persistence
echo 'export KUBECONFIG=$HOME/.kube/config' >> ~/.bashrc
source ~/.bashrc
```

### Step 4: Verify Cluster
```bash
# Get cluster info
kubectl cluster-info

# Get nodes
kubectl get nodes

# Expected output:
# NAME                       STATUS   ROLES                  AGE   VERSION
# k3d-local-k8s-server-0     Ready    control-plane,master   1m    v1.27.x
# k3d-local-k8s-agent-0      Ready    <none>                 1m    v1.27.x
# k3d-local-k8s-agent-1      Ready    <none>                 1m    v1.27.x
```

### Step 5: Check System Pods
```bash
# Get all pods in kube-system namespace
kubectl get pods -n kube-system

# Should see:
# - coredns
# - local-path-provisioner
# - metrics-server
# - etc.
```

---

## Kubernetes Deployment

### Step 1: Create Namespaces
```bash
# Copy namespace manifests to k8s/ directory

# Create namespaces
kubectl create namespace dev-microservices
kubectl create namespace databases
kubectl create namespace monitoring
kubectl create namespace ingress-nginx

# Verify
kubectl get namespaces
```

### Step 2: Create Storage Classes
```bash
# Create storage class manifest at k8s/storage-class.yaml
# See Kubernetes deployment section below

# Apply storage class
kubectl apply -f k8s/storage-class.yaml

# Verify
kubectl get storageclass
```

### Step 3: Create Persistent Volumes
```bash
# Create persistent volumes manifest at k8s/persistent-volumes.yaml

# Apply persistent volumes
kubectl apply -f k8s/persistent-volumes.yaml

# Verify
kubectl get pv
```

### Step 4: Deploy Databases
```bash
# PostgreSQL
kubectl apply -f k8s/postgres.yaml

# Redis
kubectl apply -f k8s/redis.yaml

# MongoDB
kubectl apply -f k8s/mongodb.yaml

# Verify pods are running
kubectl get pods -n databases
```

### Step 5: Deploy Microservices
```bash
# User Service
kubectl apply -f k8s/user-service.yaml

# Product Service
kubectl apply -f k8s/product-service.yaml

# Order Service
kubectl apply -f k8s/order-service.yaml

# Verify
kubectl get pods -n dev-microservices
```

### Step 6: Deploy Ingress
```bash
# Install nginx-ingress (if not already installed)
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm install nginx-ingress ingress-nginx/ingress-nginx -n ingress-nginx --create-namespace

# Apply ingress rules
kubectl apply -f k8s/ingress.yaml

# Verify
kubectl get ingress -n dev-microservices
```

### Step 7: Deploy Monitoring
```bash
# Helm repo
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Install Prometheus
helm install prometheus prometheus-community/kube-prometheus-stack -n monitoring

# Apply custom dashboards
kubectl apply -f k8s/prometheus-servicemonitor.yaml
kubectl apply -f k8s/grafana-dashboard.yaml

# Verify
kubectl get pods -n monitoring
```

---

## Verification & Testing

### Step 1: Verify Cluster Health
```bash
# Check cluster info
kubectl cluster-info

# Check nodes
kubectl get nodes -o wide

# Check all pods
kubectl get pods --all-namespaces

# Check all services
kubectl get svc --all-namespaces

# Check persistent volumes
kubectl get pv
kubectl get pvc --all-namespaces
```

### Step 2: Test Database Connectivity
```bash
# Port-forward PostgreSQL
kubectl port-forward -n databases svc/postgres 5432:5432 &

# Connect using psql (if installed)
psql -h localhost -U postgres -d microservices_db

# Or test with nc
nc -zv localhost 5432
```

### Step 3: Test Microservices
```bash
# Port-forward User Service
kubectl port-forward -n dev-microservices svc/user-service 8080:8080 &

# Test endpoint
curl http://localhost:8080/users

# Port-forward Product Service
kubectl port-forward -n dev-microservices svc/product-service 8080:8080 &
curl http://localhost:8080/products
```

### Step 4: Access Monitoring
```bash
# Port-forward Grafana
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80 &

# From local machine
ssh -L 3000:localhost:3000 -i k3d-microservices.pem ubuntu@$INSTANCE_IP

# Access: http://localhost:3000
# Login: admin / admin123

# Port-forward Prometheus
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090 &

# Access: http://localhost:9090
```

### Step 5: Check Ingress
```bash
# Get ingress IP
kubectl get ingress -A

# If using LoadBalancer (k3d doesn't provide external IP locally)
# Update /etc/hosts on your local machine:
# <EC2_PUBLIC_IP> api.local grafana.local prometheus.local

# Test ingress from EC2:
curl -H "Host: api.local" http://localhost/users
```

---

## Troubleshooting

### Issue: Docker Permission Denied
```bash
# Solution: Add user to docker group
sudo usermod -aG docker $USER
newgrp docker

# Or log out and log back in
exit
ssh -i k3d-microservices.pem ubuntu@$INSTANCE_IP
```

### Issue: K3D Cluster Won't Start
```bash
# Check Docker is running
docker ps

# Check available resources
free -h
df -h

# Delete cluster and retry
k3d cluster delete local-k8s
k3d cluster create local-k8s ...

# Check logs
docker logs k3d-local-k8s-server-0
```

### Issue: Pods Won't Start
```bash
# Check pod status
kubectl describe pod <pod-name> -n <namespace>

# Check logs
kubectl logs <pod-name> -n <namespace>

# Check node resources
kubectl top nodes
kubectl top pods -n <namespace>

# Check persistent volume claims
kubectl get pvc -n <namespace>
```

### Issue: Can't Connect to Services
```bash
# Check service exists
kubectl get svc -n <namespace>

# Check endpoints
kubectl get endpoints -n <namespace>

# Check network policy
kubectl get networkpolicy -n <namespace>

# Test connectivity
kubectl run -it --rm debug --image=busybox --restart=Never -- sh
# Inside pod: wget -O- http://service-name:port
```

### Issue: Disk Space Full
```bash
# Check usage
df -h

# Clean Docker
docker system prune -a

# Clean k3d volumes
rm -rf /tmp/k3d-storage/*

# Increase volume size
# Stop cluster and expand volume
```

---

## Cleanup

### Option 1: Stop Cluster (Keep Data)
```bash
# Stop cluster but keep persistent data
k3d cluster stop local-k8s

# Start again later
k3d cluster start local-k8s
```

### Option 2: Delete Cluster
```bash
# Delete cluster (data will be lost)
k3d cluster delete local-k8s

# Verify
k3d cluster list
```

### Option 3: Terminate EC2 Instance
```bash
# Via Terraform (recommended)
terraform destroy

# Via AWS Console:
# EC2 → Instances → Select instance → Instance State → Terminate

# Via AWS CLI:
aws ec2 terminate-instances --instance-ids <instance-id> --region us-east-1
```

### Step 4: Clean Up Local Files
```bash
# Remove Terraform state
rm -rf .terraform terraform.tfstate* .tfplan

# Remove SSH key (if no longer needed)
rm -f k3d-microservices.pem
```

---

## Security Considerations

### 1. Network Security
- [ ] Restrict SSH access to your IP only
- [ ] Use VPN for accessing remote services
- [ ] Enable VPC flow logs for monitoring

### 2. Credentials & Secrets
- [ ] Never commit AWS credentials to Git
- [ ] Use IAM roles instead of access keys when possible
- [ ] Rotate access keys regularly
- [ ] Use Kubernetes secrets for sensitive data

### 3. EC2 Instance
- [ ] Use key pairs instead of password authentication
- [ ] Keep instance and packages updated
- [ ] Use security groups to restrict traffic
- [ ] Enable CloudWatch monitoring

### 4. Data Protection
- [ ] Enable EBS encryption
- [ ] Back up persistent volumes regularly
- [ ] Use S3 for offsite backups
- [ ] Enable MFA on AWS account

---

## Useful Commands Reference

```bash
# Terraform
terraform init                           # Initialize
terraform plan                           # Plan changes
terraform apply                          # Apply changes
terraform destroy                        # Destroy resources
terraform output                         # Show outputs

# AWS CLI
aws ec2 describe-instances               # List instances
aws ec2 describe-security-groups         # List security groups
aws ec2 stop-instances                   # Stop instance
aws ec2 start-instances                  # Start instance
aws ec2 terminate-instances              # Terminate instance

# K3D
k3d cluster create                       # Create cluster
k3d cluster list                         # List clusters
k3d cluster start                        # Start cluster
k3d cluster stop                         # Stop cluster
k3d cluster delete                       # Delete cluster

# Kubernetes
kubectl get nodes                        # Get nodes
kubectl get pods -A                      # Get all pods
kubectl apply -f file.yaml               # Apply manifest
kubectl delete -f file.yaml              # Delete manifest
kubectl logs pod-name -n namespace       # Get pod logs
kubectl port-forward                     # Port forward
kubectl exec -it pod-name -- sh          # Shell into pod

# Docker
docker ps                                # List containers
docker images                            # List images
docker build                             # Build image
docker push                              # Push image
docker logs                              # Get logs
```

---

## Next Steps

1. Deploy your microservices YAML manifests
2. Set up CI/CD pipeline for automated deployments
3. Configure backup and disaster recovery
4. Set up monitoring and alerting
5. Document your deployment process
6. Plan scaling strategy

---

## Support & Documentation

- AWS Documentation: https://docs.aws.amazon.com/
- K3D Documentation: https://k3d.io/
- Kubernetes Documentation: https://kubernetes.io/docs/
- Terraform Documentation: https://www.terraform.io/docs/

