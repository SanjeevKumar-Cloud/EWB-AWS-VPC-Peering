# AWS VPC Peering: Private Inter-VPC Architecture
### EWB Cloud Labs Student Project 01 | AWS Architect Associate

![AWS](https://img.shields.io/badge/AWS-VPC%20Peering-orange?logo=amazon-aws&style=for-the-badge)
![Terraform](https://img.shields.io/badge/IaC-Terraform%20v1.16+-623CE4?logo=terraform&style=for-the-badge)
![CloudFormation](https://img.shields.io/badge/IaC-AWS%20CloudFormation-FF9900?logo=amazon-aws&style=for-the-badge)
![Security](https://img.shields.io/badge/Security-Least%20Privilege%20/32-green?style=for-the-badge)
![OpenSSH](https://img.shields.io/badge/Admin-ProxyJump%20Bastion-lightgrey?logo=gnubash&style=for-the-badge)

---

## 📌 Project Overview
This repository contains the full implementation, automated Infrastructure as Code (Terraform & CloudFormation), administrative scripts, test evidence, and viva defense documentation for the **AWS VPC Peering Project** assigned by **Team EWB Courses**.

### The Challenge
Connect two separate Virtual Private Clouds (`ewb-vpc-a` and `ewb-vpc-b`) via private IPv4 connectivity:
- Ensure both application instances (`ewb-app-a` and `ewb-app-b`) remain completely private without public IPv4 addresses or NAT gateways.
- Implement an administration Bastion host in VPC A to manage both instances securely using OpenSSH `ProxyJump`.
- Establish granular security groups (/32 host rules) and verified forward and reverse routing paths.

---

## 🏗️ Architecture Diagram

```
                              [ Local Workstation ]
                                        │
                                        │ SSH (Port 22)
                                        ▼
                            ┌───────────────────────┐
                            │   Internet Gateway    │
                            │      (ewb-igw-a)      │
                            └───────────┬───────────┘
                                        │
                    ┌───────────────────▼───────────────────┐
                    │       VPC A (10.10.0.0/16)            │
                    │                                       │
                    │  ┌─────────────────────────────────┐  │
                    │  │ Public Subnet: ewb-a-public     │  │
                    │  │ (10.10.1.0/24)                  │  │
                    │  │ [ ewb-bastion: 10.10.1.10 ]     │  │
                    │  └────────────────┬────────────────┘  │
                    │                   │                   │
                    │                   ▼                   │
                    │  ┌─────────────────────────────────┐  │
                    │  │ Private Subnet: ewb-a-private   │  │
                    │  │ (10.10.2.0/24)                  │  │
                    │  │ [ ewb-app-a: 10.10.2.10 ]       │  │
                    │  └────────────────┬────────────────┘  │
                    └───────────────────┼───────────────────┘
                                        │
                           AWS VPC Peering Connection
                                 (ewb-a-b-peer)
                                        │
                    ┌───────────────────▼───────────────────┐
                    │       VPC B (10.20.0.0/16)            │
                    │                                       │
                    │  ┌─────────────────────────────────┐  │
                    │  │ Private Subnet: ewb-b-private   │  │
                    │  │ (10.20.1.0/24)                  │  │
                    │  │ [ ewb-app-b: 10.20.1.10 ]       │  │
                    │  └─────────────────────────────────┘  │
                    │                                       │
                    │         No Internet Gateway           │
                    └───────────────────────────────────────┘
```

---

## 📂 Repository Structure

```
├── .gitignore                          # Excludes sensitive keys (.pem) and state files
├── README.md                           # Master project documentation
├── cloudformation/
│   └── vpc-peering-lab.yaml            # 1-Click AWS CloudFormation deployment template
├── terraform/
│   ├── main.tf                         # Complete VPC, Subnet, Route, SG, EC2 resource definitions
│   ├── variables.tf                    # Configurable inputs (region, IP, key name)
│   ├── outputs.tf                      # Public IPs, Private IPs, Peering ID
│   └── terraform.tfvars.example        # Sample configuration variables
├── scripts/
│   ├── setup-ssh.ps1                   # Windows PowerShell script to configure SSH & lock down key
│   └── test-connectivity.sh            # Linux bash script for automated ping & IP verification
├── ssh-config/
│   └── config                          # OpenSSH ProxyJump configuration template
├── screenshots/
│   └── SCREENSHOT_GUIDE.md             # Detailed guide and checklist for all 9 required screenshots
├── docs/
│   └── viva_and_interview_prep.md      # Comprehensive answers to all viva and defense questions
└── report/
    └── Sanjeev_Kumar_EWB_VPC_Peering.md# Complete 100-mark formatted submission report
```

---

## 📋 Network & IP Address Plan

| Resource Name | Subnet / Scope | IPv4 CIDR | Static IP | Public IPv4 |
|---|---|---|---|---|
| `ewb-vpc-a` | VPC A | 10.10.0.0/16 | N/A | N/A |
| `ewb-a-public` | Public Subnet | 10.10.1.0/24 | N/A | Enabled |
| `ewb-a-private`| Private Subnet | 10.10.2.0/24 | N/A | Disabled |
| `ewb-vpc-b` | VPC B | 10.20.0.0/16 | N/A | N/A |
| `ewb-b-private`| Private Subnet | 10.20.1.0/24 | N/A | Disabled |
| `ewb-bastion` | ewb-a-public | 10.10.1.0/24 | 10.10.1.10 | Assigned |
| `ewb-app-a` | ewb-a-private | 10.10.2.0/24 | 10.10.2.10 | None |
| `ewb-app-b` | ewb-b-private | 10.20.1.0/24 | 10.20.1.10 | None |

---

## 🚀 Quick Start Deployment

You can deploy the infrastructure manually via the AWS Console or automatically via Terraform/CloudFormation.

### Option A: 1-Click Automated Deployment with Terraform
```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
# Update my_ip in terraform.tfvars with your current public IPv4
terraform init
terraform plan
terraform apply -auto-approve
```

### Option B: 1-Click CloudFormation Deployment
1. Open the **AWS CloudFormation Console** in `ap-south-1`.
2. Choose **Create stack (with new resources)** -> **Upload a template file**.
3. Upload `cloudformation/vpc-peering-lab.yaml`.
4. Enter your parameters and launch!

---

## 🔐 SSH Access Setup (ProxyJump)

To connect to private instances without ever copying private keys to remote servers:

### On Windows (PowerShell):
```powershell
# Run the automated helper:
.\scripts\setup-ssh.ps1 -BastionPublicIP <YOUR_BASTION_PUBLIC_IP>

# Test connections:
ssh ewb-bastion
ssh ewb-app-a
ssh ewb-app-b
```

### On macOS / Linux:
```bash
chmod 400 ~/.ssh/ewb-lab.pem
cat ssh-config/config >> ~/.ssh/config
# Replace BASTION_PUBLIC_IP in ~/.ssh/config
ssh ewb-app-b
```

---

## 🧪 Verification & Acceptance Testing Matrix

| Test ID | Command / Action | Expected Result | Status |
|---|---|---|---|
| **01: Baseline** | `ping -c 4 10.20.1.10` on App-A (pre-peering) | 100% packet loss (No route) | ✅ Verified |
| **02: Forward Path** | `ping -c 4 10.20.1.10` on App-A (post-peering) | 4 replies, 0% packet loss | ✅ Verified |
| **03: Reverse Path** | `ping -c 4 10.10.2.10` on App-B | 4 replies, 0% packet loss | ✅ Verified |
| **04: Private SSH** | `ssh ewb-app-b` from workstation | Interactive shell on 10.20.1.10 | ✅ Verified |
| **05: Isolation** | Check EC2 details for App-A and App-B | Public IPv4 is blank/empty | ✅ Verified |
| **06: Controlled Failure** | Remove App-B ICMP rule, re-run ping | 100% packet loss | ✅ Verified |
| **07: Recovery** | Restore App-B ICMP rule, re-run ping | 0% packet loss resumes | ✅ Verified |

---

## 🧹 Responsible Clean-up
Once screenshots and evidence are captured:
```bash
# If using Terraform:
cd terraform
terraform destroy -auto-approve

# If manual:
# 1. Terminate EC2 instances (ewb-bastion, ewb-app-a, ewb-app-b)
# 2. Delete VPC peering connection (ewb-a-b-peer)
# 3. Delete Security Groups
# 4. Delete Subnets & Custom Route Tables
# 5. Detach and delete Internet Gateway (ewb-igw-a)
# 6. Delete VPCs (ewb-vpc-a, ewb-vpc-b)
```

---

## 🎓 Viva & Technical Defense
See [docs/viva_and_interview_prep.md](docs/viva_and_interview_prep.md) for complete answers to:
1. *Why is the return route needed?*
2. *Why is the App-B SSH source the bastion private IP?*
3. *Why does Active peering not guarantee a successful ping?*
4. *Can VPC B use VPC A's internet gateway over peering?*

---
**Author:** Sanjeev Kumar  
**Batch:** AWS Architect Associate / EWB Cloud Labs  
**Project:** 01 / October 2026
