# Azure Hub-Spoke Architecture with Microsoft Entra ID

A hands-on Azure Infrastructure-as-Code project demonstrating a secure **Hub-Spoke network architecture** with private workloads, Azure Firewall, Point-to-Site VPN, Windows VM Scale Set, Linux Flask application, Terraform, and Microsoft Entra ID authentication.

The project is designed as a reproducible cloud lab that can be deployed using Terraform and accessed privately through a P2S VPN.

---

## Architecture

```text
                         Admin Laptop
                              |
                       Point-to-Site VPN
                       172.16.100.0/24
                              |
                              v
+------------------------------------------------------+
|                  HUB VNET                            |
|                 10.0.0.0/16                         |
|                                                      |
|  GatewaySubnet              AzureFirewallSubnet      |
|  10.0.1.0/27                10.0.2.0/26             |
|       |                           |                  |
|  VPN Gateway                 Azure Firewall          |
+-------+---------------------------+------------------+
        |                           |
        | VNet Peering             | VNet Peering
        v                           v
+----------------------+     +----------------------+
|      SPOKE 1         |     |      SPOKE 2         |
|    10.1.0.0/16       |     |    10.2.0.0/16       |
|                      |     |                      |
| vmss-subnet          |     | linux-app-subnet     |
| 10.1.1.0/24          |     | 10.2.1.0/24          |
|       |              |     |       |              |
| Windows VMSS         |     | Ubuntu Linux VM      |
| IIS                  |     | 10.2.1.4             |
| ASP.NET Core         |     | Flask :5000          |
| Entra ID Login       |     | Entra ID Login       |
+----------------------+     +----------------------+
```

---

## Architecture Diagram

![Azure Hub-Spoke Architecture](Architect%20Diagram.png)

---

## Project Features

- Azure Hub-Spoke network architecture
- Infrastructure deployment using Terraform
- Centralized Azure Firewall
- User Defined Routes
- Hub-to-Spoke VNet peering
- Gateway transit
- Point-to-Site VPN
- Private Windows Server VM Scale Set
- VMSS autoscaling
- IIS
- ASP.NET Core Employee Portal
- Private Ubuntu Linux VM
- Python Flask application
- Microsoft Entra ID authentication
- MSAL authentication for Flask
- Microsoft.Identity.Web for ASP.NET Core
- Network Security Groups
- Private Spoke-to-Spoke communication
- Git-based Infrastructure-as-Code workflow

---

# Network Design

| Network | Address Space |
|---|---|
| Hub VNet | `10.0.0.0/16` |
| GatewaySubnet | `10.0.1.0/27` |
| AzureFirewallSubnet | `10.0.2.0/26` |
| Spoke 1 VNet | `10.1.0.0/16` |
| VMSS Subnet | `10.1.1.0/24` |
| Spoke 2 VNet | `10.2.0.0/16` |
| Linux App Subnet | `10.2.1.0/24` |
| Linux VM | `10.2.1.4` |
| P2S VPN Pool | `172.16.100.0/24` |

---

# Technology Stack

### Azure

- Azure Virtual Network
- Azure VPN Gateway
- Azure Firewall
- Azure VM Scale Sets
- Azure Virtual Machines
- Azure Monitor Autoscale
- Network Security Groups
- Route Tables
- Microsoft Entra ID

### Infrastructure as Code

- Terraform
- AzureRM Provider
- AzureAD Provider

### Windows Application

- Windows Server 2022
- IIS
- ASP.NET Core
- .NET
- Microsoft.Identity.Web
- OpenID Connect

### Linux Application

- Ubuntu 22.04
- Python
- Flask
- MSAL
- systemd

### Development Tools

- Git
- GitHub
- Azure CLI
- PowerShell
- VS Code
- PuTTY

---

# Repository Structure

```text
Azure-hub-spoke-entra-lab/
|
├── README.md
├── .gitignore
|
├── terraform/
│   ├── providers.tf
│   ├── variables.tf
│   ├── terraform.tfvars.example
│   ├── resource-group.tf
│   ├── hub-network.tf
│   ├── spoke1-network.tf
│   ├── spoke2-network.tf
│   ├── nsg.tf
│   ├── peering.tf
│   ├── firewall.tf
│   ├── routing.tf
│   ├── vpn-gateway.tf
│   ├── windows-vmss.tf
│   ├── autoscale.tf
│   ├── linux-vm.tf
│   ├── entra-id.tf
│   └── outputs.tf
|
├── apps/
│   ├── windows-employee-portal/
│   └── linux-flask-portal/
|
├── docs/
│   ├── architecture/
│   └── guides/
|
└── scripts/
```

---

# Deployment Workflow

```text
Clone Repository
       |
       v
Azure Login
       |
       v
Terraform Init
       |
       v
Terraform Validate
       |
       v
Terraform Plan
       |
       v
Terraform Apply
       |
       v
Hub + Spoke Networks
       |
       v
Azure Firewall
       |
       v
P2S VPN
       |
       v
Windows VMSS + Linux VM
       |
       v
Microsoft Entra App Registrations
       |
       v
Deploy Applications
       |
       v
Configure Entra Authentication
       |
       v
Connectivity Testing
```

---

# Prerequisites

Before deployment install:

- Azure CLI
- Terraform
- Git
- PowerShell
- .NET SDK
- Python 3
- VS Code

Verify:

```bash
az --version
terraform version
git --version
dotnet --version
python --version
```

---

# Azure Authentication

Login:

```bash
az login
```

Check subscription:

```bash
az account show --output table
```

If required:

```bash
az account set --subscription "<SUBSCRIPTION-ID>"
```

---

# Terraform Deployment

Navigate to Terraform:

```bash
cd terraform
```

Initialize:

```bash
terraform init
```

Format:

```bash
terraform fmt -recursive
```

Validate:

```bash
terraform validate
```

Create deployment plan:

```bash
terraform plan -out=tfplan
```

Deploy:

```bash
terraform apply tfplan
```

View outputs:

```bash
terraform output
```

---

# Point-to-Site VPN

The VPN Gateway is deployed in the Hub VNet.

```text
Gateway:
hub-spoke-lab-vpn-gateway

SKU:
VpnGw1AZ

Client Pool:
172.16.100.0/24

Protocol:
IKEv2
```

Certificate-based authentication is used for the lab.

After installing the VPN client, the administrator can privately access resources in both spokes.

Example:

```text
Laptop
   |
P2S VPN
   |
Hub VPN Gateway
   |
   +------ Spoke 1
   |
   +------ Spoke 2
```

---

# Windows Employee Portal

The Windows workload runs on a private Windows Server VM Scale Set.

```text
Windows Server 2022
       |
      IIS
       |
ASP.NET Core
       |
Employee Portal
       |
Microsoft Entra ID
```

Build:

```powershell
cd C:\WebApps\EmployeePortal

dotnet restore
dotnet build
dotnet publish -c Release -o C:\WebApps\EmployeePortal-Publish
```

The application uses:

```text
Microsoft.Identity.Web
Microsoft.Identity.Web.UI
```

---

# Windows Entra ID Authentication

Create an Entra application registration:

```text
Windows-Employee-Portal
```

Account type:

```text
Accounts in this organizational directory only
```

Configure a Web redirect URI.

Example:

```text
https://employeeportal.example.local/signin-oidc
```

Application configuration:

```json
{
  "AzureAd": {
    "Instance": "https://login.microsoftonline.com/",
    "TenantId": "<YOUR-TENANT-ID>",
    "ClientId": "<YOUR-CLIENT-ID>",
    "CallbackPath": "/signin-oidc"
  }
}
```

Authentication flow:

```text
Employee Portal
      |
      v
Microsoft Entra ID
      |
Username / Password
      |
MFA if required by policy
      |
      v
Employee Portal
```

---

# Linux Flask Application

The second application runs on Ubuntu.

```text
Private IP:
10.2.1.4

Application Port:
5000
```

Install dependencies:

```bash
sudo apt update
sudo apt install python3 python3-pip python3-venv -y

cd /opt/flaskapp

python3 -m venv .venv
source .venv/bin/activate

pip install flask msal python-dotenv requests
```

The Flask application listens on:

```text
0.0.0.0:5000
```

---

# Linux Entra ID Authentication

Create another Entra application registration:

```text
Linux-Flask-Employee-Portal
```

Configure:

```text
Platform:
Web

Redirect URI:
http://localhost:5000/getAToken
```

The Linux application uses MSAL authorization-code authentication.

Example `.env`:

```env
TENANT_ID=<YOUR-TENANT-ID>
CLIENT_ID=<YOUR-CLIENT-ID>
CLIENT_SECRET=<YOUR-CLIENT-SECRET>
REDIRECT_PATH=/getAToken
```

Never commit the real `.env` file.

Secure it:

```bash
chmod 600 /opt/flaskapp/.env
```

---

# Flask Service

Example systemd service:

```ini
[Unit]
Description=Azure Hub Spoke Flask Application
After=network.target

[Service]
User=root
WorkingDirectory=/opt/flaskapp
ExecStart=/opt/flaskapp/.venv/bin/python /opt/flaskapp/app.py
Restart=always

[Install]
WantedBy=multi-user.target
```

Enable:

```bash
sudo systemctl daemon-reload
sudo systemctl enable flaskapp
sudo systemctl restart flaskapp
```

Check:

```bash
sudo systemctl status flaskapp --no-pager
```

---

# Private Connectivity Testing

### Laptop to Linux

Connect the P2S VPN.

Then:

```bash
ssh azureadmin@10.2.1.4
```

---

### Windows VMSS to Linux

```powershell
Test-NetConnection 10.2.1.4 -Port 5000
```

Expected:

```text
TcpTestSucceeded : True
```

Test application:

```powershell
Invoke-WebRequest http://10.2.1.4:5000
```

---

### Linux to Windows

```bash
curl -I http://<WINDOWS-VMSS-PRIVATE-IP>
```

or:

```bash
curl -I https://<EMPLOYEE-PORTAL-HOSTNAME>
```

---

# Security Model

This project uses multiple security layers:

```text
Internet
   |
   X
No direct workload public access

Administrator
   |
P2S VPN
   |
Azure Private Network
   |
NSG
   |
Azure Firewall
   |
Private Workloads
   |
Microsoft Entra ID
   |
Authenticated Application
```

P2S VPN authentication and application authentication serve different purposes.

**P2S VPN**

Provides private network connectivity.

**Microsoft Entra ID**

Authenticates users to the applications.

---

# Important Security Rules

Never commit:

```text
terraform.tfvars
*.tfstate
*.ppk
*.pem
*.pfx
.env
client secrets
administrator passwords
private SSH keys
VPN private certificates
```

Use placeholders such as:

```text
<YOUR-TENANT-ID>
<YOUR-CLIENT-ID>
<YOUR-CLIENT-SECRET>
<YOUR-SUBSCRIPTION-ID>
```

---

# Terraform Secret Handling

Instead of storing a Windows password in GitHub:

### Git Bash

```bash
export TF_VAR_vm_admin_password='YOUR-STRONG-PASSWORD'
```

### PowerShell

```powershell
$env:TF_VAR_vm_admin_password = "YOUR-STRONG-PASSWORD"
```

---

# Validate Before GitHub Push

Check:

```bash
git status
```

Verify sensitive files are ignored:

```bash
git check-ignore -v terraform/terraform.tfvars
git check-ignore -v privatekey-linux.ppk
git check-ignore -v vpnclientconfiguration.zip
```

Search for possible secrets:

```bash
grep -RniE \
'password|secret|client_secret|private_key|BEGIN.*PRIVATE' \
. \
--exclude-dir=.git \
--exclude-dir=.terraform
```

Review every result before publishing.

---

# GitHub Upload

Initialize Git:

```bash
git init
git branch -M main
```

Check:

```bash
git status
```

Stage:

```bash
git add .
```

Review again:

```bash
git status
```

Commit:

```bash
git commit -m "Add Azure Hub-Spoke architecture project"
```

Configure remote:

```bash
git remote add origin https://github.com/rajan-iac/Azure-hub-spoke-entra-lab.git
```

If the remote already exists:

```bash
git remote set-url origin https://github.com/rajan-iac/Azure-hub-spoke-entra-lab.git
```

Push:

```bash
git push -u origin main
```

---

# Updating the Repository

For future changes:

```bash
git status
git add .
git commit -m "Update Azure Hub-Spoke project"
git pull --rebase origin main
git push origin main
```

---

# Deployment Guide

A complete step-by-step development guide containing:

- Terraform code for individual Azure resources
- P2S certificate configuration
- VPN Gateway deployment
- Azure Firewall
- NSGs
- Routing
- VMSS
- Linux VM
- Autoscaling
- Microsoft Entra application registrations
- ASP.NET Core authentication
- Flask/MSAL authentication
- Validation procedures
- Troubleshooting
- GitHub security

is available in:

```text
docs/Azure_Hub_Spoke_Entra_Complete_Development_Guide.pdf
```

---

# Project Validation

The completed environment should provide:

| Test | Expected Result |
|---|---|
| Hub-Spoke Peering | Connected |
| P2S VPN | Connected |
| Laptop → Windows | Private access |
| Laptop → Linux | Private access |
| Windows → Linux :5000 | Successful |
| Linux → Windows | Successful |
| IIS | Running |
| Flask | Running |
| Windows Entra Login | Successful |
| Linux Entra Login | Successful |
| VMSS Autoscaling | 1–3 instances |
| Public workload exposure | None |

---

# Learning Objectives

This project demonstrates practical experience with:

- Azure network architecture
- Hub-Spoke design
- Infrastructure as Code
- Terraform
- Private cloud networking
- Azure VPN Gateway
- Azure Firewall
- Network Security Groups
- User Defined Routes
- Windows VM Scale Sets
- Linux workloads
- IIS
- ASP.NET Core
- Python Flask
- Microsoft Entra ID
- OpenID Connect
- MSAL
- Git and GitHub

---

# Disclaimer

This repository is designed as a learning and portfolio project.

Before using the architecture in a production environment, review requirements for:

- High availability
- DNS
- TLS certificates
- Azure Key Vault
- Managed identities
- Centralized logging
- Azure Monitor
- Microsoft Defender for Cloud
- Backup and disaster recovery
- Firewall policy
- Least-privilege RBAC
- Conditional Access
- Production-grade secret management
- Remote Terraform state

---

## Author

**Rajan Bhagat**

Cloud Infrastructure / Azure / Terraform / Microsoft Entra ID

---

## Repository

`rajan-iac/Azure-hub-spoke-entra-lab`
