# 🚀 AWS K3D Kubernetes - Quick Start (Copy & Paste Ready)

## 30-Minute Complete Setup

### Prerequisites
- AWS Account
- AWS CLI configured  
- Terraform installed
- SSH client
- Key pair created in AWS

---

## Complete Setup Process

### 1. Create Working Directory
```bash
mkdir -p ~/aws-k3d
cd ~/aws-k3d

# Copy these files from outputs folder:
# - main.tf
# - variables.tf  
# - terraform.tfvars.example
# - prerequisites.sh
# - setup-k3d-cluster.sh
# - user_data.sh
```

### 2. Configure Terraform
```bash
cp terraform.tfvars.example terraform.tfvars

# Edit with your values
cat > terraform.tfvars << 'TFVARS'
aws_region          = "us-east-1"
instance_type       = "t3.large"
root_volume_size    = 50
key_pair_name       = "k3d-microservices"
allowed_ssh_cidr    = ["YOUR.IP.ADDRESS/32"]
environment         = "development"
enable_monitoring   = true

tags = {
  CreatedBy = "Terraform"
  Purpose   = "K3d-Microservices"
}
TFVARS
```

### 3. Deploy AWS Infrastructure
```bash
# Initialize Terraform
terraform init

# Plan and verify
terraform plan -out=tfplan

# Deploy (takes ~3 minutes)
terraform apply tfplan

# Get instance IP
INSTANCE_IP=$(terraform output -raw instance_public_ip)
echo "Instance IP: $INSTANCE_IP"
```

### 4. Connect to EC2
```bash
# SSH into instance
ssh -i ~/path/to/k3d-microservices.pem ubuntu@$INSTANCE_IP

# Once connected, run prerequisites
sudo bash /home/ubuntu/k3d-microservices/scripts/prerequisites.sh

# This takes 5-10 minutes and installs:
# - Docker
# - kubectl
# - k3d
# - Helm
# - All dependencies

# Log out and back in
exit
ssh -i ~/path/to/k3d-microservices.pem ubuntu@$INSTANCE_IP
```

### 5. Create K3D Cluster
```bash
cd /home/ubuntu/k3d-microservices

# Create cluster (takes 2-3 minutes)
bash setup-k3d-cluster.sh

# Verify
kubectl get nodes
# Should show 3 nodes ready
```

### 6. Verify Everything
```bash
# Check all namespaces
kubectl get namespaces

# Check all pods
kubectl get pods --all-namespaces

# Check services
kubectl get svc --all-namespaces

# Check persistent volumes
kubectl get pv
```

---

## Access Monitoring

### Grafana
```bash
# From EC2:
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80 &

# From local machine:
ssh -L 3000:localhost:3000 -i k3d-microservices.pem ubuntu@$INSTANCE_IP

# Access: http://localhost:3000
# Login: admin/admin123
```

### Prometheus  
```bash
# From EC2:
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090 &

# Access: http://localhost:9090
```

---

## Deploy Microservices

### Copy Your YAML Files
```bash
cd /home/ubuntu/k3d-microservices/k8s

# Copy all your manifests here:
# - storage-class.yaml
# - persistent-volumes.yaml
# - postgres.yaml
# - redis.yaml
# - mongodb.yaml
# - user-service.yaml
# - product-service.yaml
# - order-service.yaml
# - ingress.yaml
```

### Deploy Everything
```bash
# Deploy storage
kubectl apply -f storage-class.yaml
kubectl apply -f persistent-volumes.yaml

# Deploy databases
kubectl apply -f postgres.yaml
kubectl apply -f redis.yaml
kubectl apply -f mongodb.yaml

# Deploy services
kubectl apply -f user-service.yaml
kubectl apply -f product-service.yaml
kubectl apply -f order-service.yaml

# Deploy ingress
kubectl apply -f ingress.yaml

# Verify
kubectl get pods --all-namespaces
```

---

## Cleanup

### Stop Everything (Keep Data)
```bash
k3d cluster stop local-k8s

# Stop EC2
aws ec2 stop-instances --instance-ids <instance-id> --region us-east-1

# Only pay storage costs (~$5/month)
```

### Delete Everything
```bash
# Delete Terraform resources
terraform destroy

# Confirm: yes

# All resources deleted, no more charges
```

---

## Commands Reference

```bash
# Terraform
terraform init                        # Initialize
terraform plan                        # Show changes
terraform apply                       # Deploy
terraform destroy                     # Delete
terraform output                      # Show outputs

# Kubernetes
kubectl get nodes                     # List nodes
kubectl get pods -A                   # List all pods
kubectl apply -f file.yaml            # Apply manifest
kubectl delete -f file.yaml           # Delete manifest
kubectl logs pod-name -n namespace    # Get logs
kubectl port-forward                  # Port forward
kubectl exec -it pod -- sh            # Shell into pod

# K3D
k3d cluster list                      # List clusters
k3d cluster delete local-k8s          # Delete cluster
k3d kubeconfig get local-k8s          # Get config

# AWS CLI
aws ec2 describe-instances            # List instances
aws ec2 stop-instances                # Stop instance
aws ec2 terminate-instances           # Delete instance
```

---

## Troubleshooting Quick Reference

### Docker Permission Denied
```bash
sudo usermod -aG docker ubuntu
exit  # Log out
# Log back in
```

### K3D Won't Start
```bash
# Check Docker
docker ps

# Check memory
free -h

# Delete and retry
k3d cluster delete local-k8s
bash setup-k3d-cluster.sh
```

### Pods Won't Start
```bash
# Check status
kubectl describe pod pod-name -n namespace

# Check logs
kubectl logs pod-name -n namespace

# Check disk space
df -h
```

### Can't SSH
```bash
# Check security group allows SSH
# Check key pair name matches
# Check key permissions: chmod 400 key.pem
```

---

## Cost (Monthly Estimate)

| Item | Cost |
|------|------|
| EC2 t3.large | $30 |
| Storage (50GB) | $5 |
| Data transfer | $0-5 |
| **Total** | **$35-40** |

---

## Security Notes

✅ **DO:**
- Use your specific IP for SSH (not 0.0.0.0/0)
- Keep AWS credentials secure
- Use VPN for remote access
- Monitor CloudWatch

❌ **DON'T:**
- Commit AWS credentials to Git
- Use default/weak passwords
- Open all ports to 0.0.0.0/0
- Ignore security group warnings

---

## Files Needed

Download these from outputs folder:
1. `main.tf` - AWS infrastructure
2. `variables.tf` - Variable definitions
3. `terraform.tfvars.example` - Example config
4. `prerequisites.sh` - Installation script
5. `setup-k3d-cluster.sh` - K3D setup
6. `user_data.sh` - EC2 initialization
7. `AWS-DEPLOYMENT-GUIDE.md` - Full guide
8. `README-AWS.md` - Complete documentation

---

## Success Checklist

- [ ] AWS account created
- [ ] EC2 key pair created
- [ ] AWS CLI configured
- [ ] Terraform installed
- [ ] terraform.tfvars configured
- [ ] Infrastructure deployed
- [ ] SSH connected to EC2
- [ ] Prerequisites script completed
- [ ] K3D cluster created
- [ ] All pods running
- [ ] Services accessible
- [ ] Monitoring working

---

## Next Steps

1. Deploy your microservices YAML files
2. Test all endpoints
3. Check Grafana dashboards
4. Set up backups
5. Configure auto-scaling
6. Plan for production

---

## Support

- **AWS:** https://docs.aws.amazon.com/
- **K3D:** https://k3d.io/
- **Kubernetes:** https://kubernetes.io/
- **Terraform:** https://www.terraform.io/

---

**Ready to Deploy!** 🚀

Copy all files and follow the 30-minute setup above.

