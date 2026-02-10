# AWS EC2 K3D Kubernetes - Complete Setup Guide

## 🎯 Overview

This guide provides a **complete, copy-paste ready** solution to deploy Kubernetes microservices on AWS EC2 using k3d.

### What You'll Get
- ✅ Fully automated AWS infrastructure setup using Terraform
- ✅ EC2 instance pre-configured with Docker, kubectl, k3d, and Helm
- ✅ Kubernetes cluster ready for microservices deployment
- ✅ All prerequisites installed automatically
- ✅ Production-grade configuration files
- ✅ Complete documentation and scripts

### System Architecture
```
AWS Account
  └── EC2 Instance (t3.large)
      └── Docker
          └── k3d Kubernetes Cluster
              ├── PostgreSQL
              ├── Redis  
              ├── MongoDB
              ├── User Service
              ├── Product Service
              ├── Order Service
              ├── Prometheus
              └── Grafana
```

---

## 📋 Prerequisites

### On Your Local Machine
- **AWS Account** - Active account with billing enabled
- **AWS CLI** - Installed and configured with credentials
- **Terraform** - Version 1.0 or higher
- **SSH Client** - For connecting to EC2 instance
- **Text Editor** - For editing configuration files

### AWS Permissions Required
- EC2 Full Access
- VPC Full Access
- IAM Role and Instance Profile creation
- CloudWatch (optional)

---

## 🚀 Quick Start (30 Minutes)

### Step 1: Prepare Local Environment (5 min)
```bash
# Create working directory
mkdir -p ~/aws-k3d-deployment
cd ~/aws-k3d-deployment

# Download files from outputs folder:
# - main.tf
# - variables.tf
# - terraform.tfvars.example
# - prerequisites.sh
# - setup-k3d-cluster.sh
# - user_data.sh

# Copy example to actual config
cp terraform.tfvars.example terraform.tfvars

# Edit configuration
nano terraform.tfvars  # or vim, or your preferred editor
```

### Step 2: Configure Terraform (5 min)

Edit `terraform.tfvars`:
```hcl
# Required changes:
aws_region     = "us-east-1"           # Your region
instance_type  = "t3.large"           # 2 CPU, 8GB RAM
root_volume_size = 50                 # 50GB disk
key_pair_name  = "k3d-microservices"  # EC2 key pair name
allowed_ssh_cidr = ["YOUR_IP/32"]     # Your IP for SSH
```

### Step 3: Deploy Infrastructure (10 min)
```bash
# Initialize Terraform
terraform init

# Plan deployment
terraform plan -out=tfplan

# Apply configuration
terraform apply tfplan

# Save outputs
terraform output -json > outputs.json
```

### Step 4: Connect and Setup (10 min)
```bash
# Get instance IP
INSTANCE_IP=$(terraform output -raw instance_public_ip)

# SSH into instance
ssh -i ~/path/to/k3d-microservices.pem ubuntu@$INSTANCE_IP

# Run prerequisites (takes 5-10 minutes)
sudo bash /home/ubuntu/k3d-microservices/scripts/prerequisites.sh

# Log out and back in for docker group changes
exit
ssh -i ~/path/to/k3d-microservices.pem ubuntu@$INSTANCE_IP

# Create k3d cluster (takes 2-3 minutes)
cd /home/ubuntu/k3d-microservices
bash scripts/setup-k3d-cluster.sh
```

### Step 5: Verify Cluster
```bash
# Check nodes
kubectl get nodes

# Check namespaces
kubectl get namespaces

# Check all pods
kubectl get pods --all-namespaces
```

**Cluster is ready!** 🎉

---

## 📁 File Structure

```
aws-k3d-deployment/
├── main.tf                          # AWS infrastructure definition
├── variables.tf                     # Variable definitions
├── terraform.tfvars                 # Variable values (YOUR CONFIG)
├── terraform.tfvars.example         # Example values
├── prerequisites.sh                 # Installation script (auto-run)
├── setup-k3d-cluster.sh            # K3D setup script
├── user_data.sh                     # EC2 initialization
├── AWS-DEPLOYMENT-GUIDE.md         # Detailed guide
├── README-AWS.md                    # This file
├── .terraform/                      # Terraform state (auto-generated)
├── terraform.tfstate               # State file (auto-generated)
├── outputs.json                     # Outputs (auto-generated)
└── k3d-microservices.pem           # SSH key (download from AWS)
```

---

## 🔧 Detailed Steps

### Step 1: AWS Account Setup (If New)

#### Create AWS Account
1. Go to https://aws.amazon.com
2. Click "Create an AWS Account"
3. Follow the signup process
4. Verify email and card

#### Create EC2 Key Pair
```bash
# Option 1: Via AWS Console
# EC2 → Key Pairs → Create Key Pair
# Name: k3d-microservices
# Format: .pem
# Download: k3d-microservices.pem
# Set permissions: chmod 400 k3d-microservices.pem

# Option 2: Via AWS CLI
aws ec2 create-key-pair --key-name k3d-microservices \
  --region us-east-1 --query 'KeyMaterial' --output text > k3d-microservices.pem
chmod 400 k3d-microservices.pem
```

#### Configure AWS CLI
```bash
# Install AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Configure credentials
aws configure
# Access Key ID: [paste your access key]
# Secret Access Key: [paste your secret key]
# Region: us-east-1 (or your region)
# Output format: json

# Verify
aws sts get-caller-identity
```

### Step 2: Install Terraform

#### Linux
```bash
wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip
unzip terraform_1.6.0_linux_amd64.zip
sudo mv terraform /usr/local/bin/
terraform version
```

#### macOS
```bash
brew install terraform
terraform version
```

#### Windows
```powershell
# Use Chocolatey
choco install terraform

# Or download from
# https://www.terraform.io/downloads
```

### Step 3: Configure Terraform

Create `terraform.tfvars`:
```hcl
# ============================================================================
# IMPORTANT: Customize these values
# ============================================================================

# AWS region
aws_region = "us-east-1"

# Instance type: t3.large = 2 CPU, 8GB RAM (minimum recommended)
#               t3.xlarge = 4 CPU, 16GB RAM (production)
instance_type = "t3.large"

# Disk size (minimum 30GB, 50GB recommended)
root_volume_size = 50

# EC2 Key Pair name (MUST CREATE IN AWS FIRST!)
key_pair_name = "k3d-microservices"

# Your IP for SSH access (get your IP: curl checkip.amazonaws.com)
# SECURITY: Use your specific IP, not "0.0.0.0/0"
allowed_ssh_cidr = ["YOUR_IP/32"]

# Environment
environment = "development"

# Enable monitoring
enable_monitoring = true

# Tags for resource tracking
tags = {
  CreatedBy  = "Terraform"
  Purpose    = "K3d-Microservices"
}
```

### Step 4: Deploy with Terraform

```bash
# Navigate to directory
cd ~/aws-k3d-deployment

# Initialize (downloads provider plugins)
terraform init

# Validate configuration
terraform validate

# Plan (show what will be created)
terraform plan -out=tfplan

# Review the plan output carefully!

# Apply (create resources)
terraform apply tfplan

# Wait 2-3 minutes for completion
```

### Step 5: Connect to EC2

```bash
# Get instance IP from terraform output
INSTANCE_IP=$(terraform output -raw instance_public_ip)
echo "Connecting to: $INSTANCE_IP"

# SSH into instance
ssh -i ~/path/to/k3d-microservices.pem ubuntu@$INSTANCE_IP

# Or if key is in current directory
ssh -i ./k3d-microservices.pem ubuntu@$INSTANCE_IP
```

### Step 6: Run Prerequisites

```bash
# SSH into instance first
ssh -i k3d-microservices.pem ubuntu@<PUBLIC_IP>

# Run prerequisites as root (takes 5-10 minutes)
sudo bash /home/ubuntu/k3d-microservices/scripts/prerequisites.sh

# This script installs:
# ✓ Docker
# ✓ kubectl
# ✓ k3d
# ✓ Helm
# ✓ jq, git, wget, net-tools, etc.
# ✓ Configures Docker daemon
# ✓ Sets up kubeconfig

# At the end, it will show:
# "Ready to create k3d cluster!"

# Log out and back in for docker group changes
exit
ssh -i k3d-microservices.pem ubuntu@<PUBLIC_IP>
```

### Step 7: Create K3D Cluster

```bash
# Navigate to work directory
cd /home/ubuntu/k3d-microservices

# Create cluster (takes 2-3 minutes)
bash setup-k3d-cluster.sh

# This creates:
# ✓ 3-node k3d cluster (1 server + 2 agents)
# ✓ Namespaces (dev-microservices, databases, monitoring)
# ✓ nginx-ingress
# ✓ Prometheus + Grafana stack
# ✓ Configured kubeconfig

# Verify with:
kubectl get nodes
kubectl get namespaces
kubectl get pods --all-namespaces
```

### Step 8: Deploy Microservices

```bash
# Copy YAML manifests to k8s/ directory
# Files should include:
# - storage-class.yaml
# - persistent-volumes.yaml
# - postgres.yaml
# - redis.yaml
# - mongodb.yaml
# - user-service.yaml
# - product-service.yaml
# - order-service.yaml
# - ingress.yaml
# - prometheus-servicemonitor.yaml
# - grafana-dashboard.yaml

# Deploy storage
kubectl apply -f k8s/storage-class.yaml
kubectl apply -f k8s/persistent-volumes.yaml

# Deploy databases
kubectl apply -f k8s/postgres.yaml
kubectl apply -f k8s/redis.yaml
kubectl apply -f k8s/mongodb.yaml

# Deploy microservices
kubectl apply -f k8s/user-service.yaml
kubectl apply -f k8s/product-service.yaml
kubectl apply -f k8s/order-service.yaml

# Deploy ingress and monitoring
kubectl apply -f k8s/ingress.yaml
kubectl apply -f k8s/prometheus-servicemonitor.yaml
kubectl apply -f k8s/grafana-dashboard.yaml

# Verify deployments
kubectl get pods --all-namespaces
kubectl get svc --all-namespaces
```

---

## 🔍 Verification

### Check Cluster Status
```bash
# Get cluster info
kubectl cluster-info

# Get nodes
kubectl get nodes -o wide

# Get all pods
kubectl get pods --all-namespaces

# Check resource usage
kubectl top nodes
kubectl top pods --all-namespaces

# Get services
kubectl get svc --all-namespaces

# Check persistent volumes
kubectl get pv
kubectl get pvc --all-namespaces
```

### Test Services

```bash
# Port-forward to service
kubectl port-forward -n dev-microservices svc/user-service 8080:8080 &

# Test from another terminal
curl http://localhost:8080/users

# Or test from inside cluster
kubectl run -it --rm debug --image=busybox --restart=Never -- sh
# Inside pod:
wget -O- http://user-service:8080/users
```

### Access Monitoring

```bash
# Get Grafana password
kubectl get secret -n monitoring prometheus-grafana -o jsonpath="{.data.admin-password}" | base64 -d

# Port-forward Grafana
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80 &

# From local machine
ssh -L 3000:localhost:3000 -i k3d-microservices.pem ubuntu@<PUBLIC_IP>

# Access: http://localhost:3000
# Login: admin / <password-from-above>
```

---

## 🛠️ Troubleshooting

### Issue: "Terraform command not found"
```bash
# Install Terraform
wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip
unzip terraform_1.6.0_linux_amd64.zip
sudo mv terraform /usr/local/bin/

# Verify
terraform version
```

### Issue: "AWS credentials not configured"
```bash
# Configure AWS CLI
aws configure

# Or set environment variables
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_DEFAULT_REGION="us-east-1"

# Verify
aws sts get-caller-identity
```

### Issue: "Key pair not found"
```bash
# Create key pair in AWS Console:
# EC2 → Key Pairs → Create Key Pair
# Download .pem file
# chmod 400 k3d-microservices.pem

# Or create via CLI:
aws ec2 create-key-pair --key-name k3d-microservices \
  --region us-east-1 --query 'KeyMaterial' --output text > k3d-microservices.pem
chmod 400 k3d-microservices.pem
```

### Issue: "Permission denied (publickey)"
```bash
# Check SSH key permissions
ls -l k3d-microservices.pem
# Should show: -r--------

# Fix permissions
chmod 400 k3d-microservices.pem

# Check key pair name in AWS
aws ec2 describe-key-pairs --region us-east-1

# Make sure key_pair_name in terraform.tfvars matches
```

### Issue: "Docker permission denied"
```bash
# Add user to docker group
sudo usermod -aG docker ubuntu

# Log out and back in for changes to take effect
exit
ssh -i k3d-microservices.pem ubuntu@<PUBLIC_IP>

# Verify
docker ps
```

### Issue: "K3D cluster won't start"
```bash
# Check Docker is running
docker ps

# Check available memory
free -h
# Need at least 4GB

# Delete and recreate cluster
k3d cluster delete local-k8s
bash setup-k3d-cluster.sh

# Check logs
docker logs k3d-local-k8s-server-0
```

### Issue: "Pods stuck in Pending"
```bash
# Check PVC status
kubectl get pvc --all-namespaces

# Check PV status
kubectl get pv

# Describe PVC for events
kubectl describe pvc <pvc-name> -n <namespace>

# Check node disk space
df -h
# If low, clean Docker: docker system prune -a
```

---

## 💰 Cost Estimates

### Monthly Costs (Approximate)

| Component | t3.large | t3.xlarge | Notes |
|-----------|----------|-----------|-------|
| EC2 Instance | $30 | $60 | On-demand hourly rate × 730 hours |
| EBS Storage (50GB) | $5 | $5 | $0.10/GB/month |
| Data Transfer | $0-5 | $0-5 | Depends on usage |
| **Total** | **$35-40** | **$65-70** | For development |

### Cost Optimization
```bash
# Use Savings Plans for 40% discount
# Use Spot instances for testing (70% discount)
# Stop instance when not needed (AWS Console or CLI)
# Monitor CloudWatch for optimization opportunities
```

---

## 🔒 Security Checklist

- [ ] Change allowed_ssh_cidr to your IP (not 0.0.0.0/0)
- [ ] Use VPN for accessing services
- [ ] Enable MFA on AWS account
- [ ] Rotate AWS access keys monthly
- [ ] Use IAM roles instead of access keys
- [ ] Enable EBS encryption in Terraform
- [ ] Back up persistent volumes regularly
- [ ] Monitor CloudWatch logs
- [ ] Use VPC security groups properly
- [ ] Keep instance and packages updated

---

## 📊 Monitoring

### CloudWatch Monitoring
```bash
# Already enabled by Terraform
# Check in AWS Console → CloudWatch

# Key metrics to watch:
# - EC2 CPU utilization
# - Memory usage
# - Disk space
# - Network traffic
# - Docker container metrics
```

### Kubernetes Monitoring
```bash
# Prometheus metrics
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090 &
# Access: http://localhost:9090

# Grafana dashboards
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80 &
# Access: http://localhost:3000
```

---

## 🗑️ Cleanup

### Option 1: Stop Cluster (Keep Data)
```bash
# Stop k3d cluster
k3d cluster stop local-k8s

# Stop EC2 instance (AWS Console or CLI)
aws ec2 stop-instances --instance-ids <instance-id> --region us-east-1

# Cost: Only storage charges (~$5/month)
```

### Option 2: Delete Cluster
```bash
# Delete k3d cluster
k3d cluster delete local-k8s

# Data will be lost!
```

### Option 3: Terminate Everything
```bash
# Destroy all AWS resources with Terraform
terraform destroy

# Confirm: yes

# Wait for completion (~5 minutes)
# All resources deleted, no more charges
```

### Step 4: Cleanup Local Files
```bash
# Remove Terraform state files
rm -rf .terraform terraform.tfstate* .tfplan

# Backup important data first!
# Then delete working directory if needed
rm -rf ~/aws-k3d-deployment
```

---

## 📚 Reference

### Important Files
- **AWS-DEPLOYMENT-GUIDE.md** - Detailed step-by-step guide
- **prerequisites.sh** - All installation scripts
- **setup-k3d-cluster.sh** - K3D cluster creation
- **main.tf** - AWS infrastructure definition
- **variables.tf** - Terraform variable definitions

### Useful Commands
```bash
# Terraform
terraform init
terraform plan
terraform apply
terraform destroy
terraform output

# AWS CLI
aws ec2 describe-instances
aws ec2 describe-security-groups
aws ec2 stop-instances
aws ec2 start-instances
aws ec2 terminate-instances

# K3D
k3d cluster create
k3d cluster list
k3d cluster delete

# Kubernetes
kubectl get nodes
kubectl get pods --all-namespaces
kubectl apply -f file.yaml
kubectl delete -f file.yaml
kubectl port-forward
kubectl logs
```

### Documentation Links
- AWS EC2: https://docs.aws.amazon.com/ec2/
- K3D: https://k3d.io/
- Kubernetes: https://kubernetes.io/docs/
- Terraform: https://www.terraform.io/docs/

---

## ✅ Success Checklist

After completion, you should have:

- [ ] AWS account with EC2 instance running
- [ ] k3d Kubernetes cluster active
- [ ] PostgreSQL, Redis, MongoDB deployed
- [ ] 3 microservices running
- [ ] Prometheus + Grafana monitoring
- [ ] nginx-ingress controller
- [ ] All pods in Running state
- [ ] Services accessible
- [ ] Monitoring dashboards available

---

## 🎉 You're Ready!

Your Kubernetes microservices cluster on AWS is now ready for:
- Development and testing
- Production deployment (with additional config)
- Learning Kubernetes and microservices
- Running containerized applications

**Next Steps:**
1. Deploy your microservices
2. Set up CI/CD pipeline
3. Configure backups
4. Monitor and optimize
5. Scale as needed

---

**Status**: ✅ Complete & Ready  
**Version**: 1.0  
**Date**: February 2025  

**Happy Deploying! 🚀**

