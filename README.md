Yes. Below is the **step-by-step master deployment sequence** I recommend using as the main runbook for your Azure Hub-Spoke project. It follows the project you actually built: **Hub + P2S VPN + Azure Firewall + Windows VMSS/.NET/IIS + Linux/Flask + Microsoft Entra ID application login**.

I also checked the current Microsoft guidance. Microsoft continues to recommend the authorization-code flow for web apps; `Microsoft.Identity.Web` is the supported approach for ASP.NET Core, while Microsoft provides MSAL-based guidance for Flask. :chatgpt-content-reference{index="0"}

# Azure Hub-Spoke Project — Complete Deployment Guide

## 1. Final architecture

```text
                           MICROSOFT ENTRA ID
                         Authentication + MFA
                               /        \
                              /          \
                    Windows App        Linux App
                         |                 |
                         |                 |
HOME LAPTOP              |                 |
172.16.100.x             |                 |
     |                   |                 |
     | P2S VPN           |                 |
     v                   |                 |
+------------------------------------------------+
|                HUB VNET 10.0.0.0/16            |
|                                                |
| GatewaySubnet                                  |
| 10.0.1.0/27                                    |
|      |                                         |
| Azure VPN Gateway                              |
|                                                |
| AzureFirewallSubnet                            |
| 10.0.2.0/26                                    |
|      |                                         |
| Azure Firewall                                 |
+--------------------+---------------------------+
                     |
              VNet Peering
              /          \
             /            \
            v              v

+----------------------+   +----------------------+
| SPOKE 1              |   | SPOKE 2              |
| 10.1.0.0/16          |   | 10.2.0.0/16          |
|                      |   |                      |
| 10.1.1.0/24          |   | 10.2.1.0/24          |
| Windows VMSS         |   | Ubuntu VM            |
| Windows Server 2022  |   | 10.2.1.4             |
| IIS                  |   | Python Flask         |
| ASP.NET Core/.NET    |   | Port 5000            |
| Employee Portal      |   | systemd              |
| Entra ID Login       |   | Entra ID Login       |
+----------------------+   +----------------------+
```

There are **no public IPs on the application workloads**. Your laptop reaches them through the P2S VPN.

---

# PHASE 1 — Prepare the workstation

## Step 1 — Install the tools

On your Windows laptop install:

```text
Azure CLI
Terraform
Azure VPN Client
PuTTY
PuTTYgen
Visual Studio Code
.NET SDK
```

Verify:

```powershell
az --version
terraform version
dotnet --version
```

Then authenticate:

```powershell
az login
```

Verify the active subscription:

```powershell
az account show --output table
```

If necessary:

```powershell
az account set --subscription "<SUBSCRIPTION-ID>"
```

---

# PHASE 2 — Create the Azure network

## Step 2 — Create the resource group

Your lab resource group was:

```text
hub-spoke-lab-rg
```

Example CLI equivalent:

```powershell
az group create `
  --name hub-spoke-lab-rg `
  --location centralindia
```

---

# PHASE 3 — Create Hub VNet

## Step 3 — Create Hub

Use:

```text
Hub VNet
10.0.0.0/16
```

The Hub contains only the two special subnets used in your final design:

```text
GatewaySubnet
10.0.1.0/27

AzureFirewallSubnet
10.0.2.0/26
```

These names matter. Azure expects the reserved subnet names for the gateway and firewall.

---

# PHASE 4 — Create Spoke 1

## Step 4 — Windows workload network

Create:

```text
Spoke 1 VNet
10.1.0.0/16

VMSS subnet
10.1.1.0/24
```

This subnet will contain:

```text
Windows Server 2022 VMSS
IIS
ASP.NET Core Employee Portal
```

---

# PHASE 5 — Create Spoke 2

## Step 5 — Linux workload network

Create:

```text
Spoke 2 VNet
10.2.0.0/16

Linux subnet
10.2.1.0/24
```

Your Linux VM eventually received:

```text
Hostname: linuxapp01
Private IP: 10.2.1.4
OS: Ubuntu 22.04.5 LTS
```

---

# PHASE 6 — Configure VNet peering

## Step 6 — Hub ↔ Spoke 1

Create:

```text
Hub → Spoke 1
Spoke 1 → Hub
```

## Step 7 — Hub ↔ Spoke 2

Create:

```text
Hub → Spoke 2
Spoke 2 → Hub
```

Because the VPN Gateway lives in the Hub and VPN clients need to reach the Spokes, configure **gateway transit** appropriately. Azure supports this specifically so peered VNets can use a gateway located in another VNet. :chatgpt-content-reference{index="1"}

Conceptually:

```text
Hub peering:
Allow gateway transit = Enabled

Spoke peering:
Use remote gateway = Enabled
```

Also allow forwarded traffic where your routing design requires it.

---

# PHASE 7 — Deploy Azure Firewall

## Step 8 — Create Firewall

Deploy Azure Firewall into:

```text
AzureFirewallSubnet
10.0.2.0/26
```

The firewall becomes the centralized security/routing component.

Think of the three networking controls this way:

```text
NSG
  ↓
Controls which ports/sources are allowed

Route Table
  ↓
Controls where packets go

Azure Firewall
  ↓
Inspects and controls routed traffic centrally
```

For a learning lab, configure only the rules required for the workloads.

---

# PHASE 8 — Deploy P2S VPN

## Step 9 — Create VPN Gateway

Deploy the VPN Gateway in:

```text
GatewaySubnet
10.0.1.0/27
```

Your project used a route-based VPN Gateway.

Microsoft's current P2S certificate design uses a trusted root public certificate on the gateway and a corresponding client certificate on each connecting machine. :chatgpt-content-reference{index="2"}

Configure the client pool:

```text
172.16.100.0/24
```

---

## Step 10 — Generate P2S certificates

Run PowerShell on your laptop:

```powershell
$root = New-SelfSignedCertificate `
-Type Custom `
-KeySpec Signature `
-Subject "CN=HubSpokeP2SRoot" `
-KeyExportPolicy Exportable `
-HashAlgorithm sha256 `
-KeyLength 2048 `
-CertStoreLocation "Cert:\CurrentUser\My" `
-KeyUsageProperty Sign `
-KeyUsage CertSign
```

Create the client certificate:

```powershell
$client = New-SelfSignedCertificate `
-Type Custom `
-DnsName "HubSpokeP2SClient" `
-KeySpec Signature `
-Subject "CN=HubSpokeP2SClient" `
-KeyExportPolicy Exportable `
-HashAlgorithm sha256 `
-KeyLength 2048 `
-CertStoreLocation "Cert:\CurrentUser\My" `
-Signer $root
```

Export the root public certificate and upload it under:

```text
VPN Gateway
→ Point-to-site configuration
→ Root certificates
```

Do **not** upload the root private key.

---

# PHASE 9 — Connect laptop to Azure

## Step 11 — Download VPN configuration

From the VPN Gateway:

```text
Point-to-site configuration
        ↓
Download VPN client
```

Import the configuration into the VPN client and connect.

Your working client received:

```text
172.16.100.2
```

At this point the traffic path becomes:

```text
Laptop
172.16.100.2
      ↓
P2S VPN
      ↓
VPN Gateway
      ↓
Hub
      ↓
Peering
   ↙       ↘
Spoke 1   Spoke 2
```

---

# PHASE 10 — Deploy Windows VMSS

## Step 12 — Create Windows VMSS

Deploy:

```text
Name:
hub-spoke-lab-web-vmss

OS:
Windows Server 2022

SKU:
Standard_B2s

Subnet:
Spoke 1 / 10.1.1.0/24
```

Do not assign public IPs.

Access the VMSS instance through the VPN.

---

# PHASE 11 — Install IIS

## Step 13 — Connect to Windows instance

Once VPN is connected, RDP to the VMSS instance's private address.

Install IIS:

```powershell
Install-WindowsFeature Web-Server -IncludeManagementTools
```

Verify:

```powershell
Get-WindowsFeature Web-Server
```

Check service:

```powershell
Get-Service W3SVC
```

Test locally:

```powershell
Invoke-WebRequest http://localhost
```

You should receive an HTTP response.

---

# PHASE 12 — Prepare the .NET Employee Portal

## Step 14 — Application folder

Your application was maintained under:

```text
C:\WebApps\EmployeePortal
```

Enter the folder:

```powershell
cd C:\WebApps\EmployeePortal
```

Restore dependencies:

```powershell
dotnet restore
```

Build:

```powershell
dotnet build
```

Check packages:

```powershell
dotnet list package
```

Your Entra integration used:

```text
Microsoft.Identity.Web
Microsoft.Identity.Web.UI
```

Publish:

```powershell
dotnet publish -c Release `
-o C:\WebApps\EmployeePortal-Publish
```

---

# PHASE 13 — Configure IIS

## Step 15 — Create Employee Portal site

Application files ultimately go under:

```text
C:\inetpub\EmployeePortal
```

Import IIS PowerShell:

```powershell
Import-Module WebAdministration
```

When updating the application:

```powershell
Stop-WebAppPool -Name "EmployeePortal"
```

Copy the new application:

```powershell
Remove-Item "C:\inetpub\EmployeePortal\*" `
-Recurse -Force
```

Then:

```powershell
Copy-Item `
"C:\WebApps\EmployeePortal-Publish\*" `
"C:\inetpub\EmployeePortal\" `
-Recurse -Force
```

Restart:

```powershell
Start-WebAppPool -Name "EmployeePortal"
```

Finally:

```powershell
iisreset
```

This avoids the DLL-lock problem you encountered when IIS still had the application binaries open.

---

# PHASE 14 — Register Windows App in Entra ID

## Step 16 — Create App Registration

Azure Portal:

```text
Microsoft Entra ID
        ↓
App registrations
        ↓
New registration
```

Example name:

```text
EmployeePortal-Windows
```

For your organization-only lab, choose:

```text
Accounts in this organizational directory only
```

Microsoft's current ASP.NET Core guidance uses a **Web** redirect URI ending in `/signin-oidc`. :chatgpt-content-reference{index="3"}

---

## Step 17 — Record IDs

From Overview copy:

```text
Application (client) ID
Directory (tenant) ID
```

You need both in the application.

---

# PHASE 15 — Configure Windows redirect URI

## Step 18 — Add Web platform

Go to:

```text
App registration
→ Authentication
→ Add a platform
→ Web
```

During local testing, Microsoft's documented pattern is:

```text
https://localhost:5001/signin-oidc
```

For your IIS-hosted application, the registered redirect URI must match the actual URL used to reach the application.

For example:

```text
https://employeeportal.example/signin-oidc
```

The important rule is:

```text
Protocol + hostname + port + path
```

must match.

Otherwise Entra returns:

```text
AADSTS50011
```

which Microsoft documents as a redirect-URI mismatch. :chatgpt-content-reference{index="4"}

---

# PHASE 16 — Configure .NET authentication

## Step 19 — Install Identity packages

From the project directory:

```powershell
dotnet add package Microsoft.Identity.Web
```

Then:

```powershell
dotnet add package Microsoft.Identity.Web.UI
```

Restore:

```powershell
dotnet restore
```

---

## Step 20 — Configure appsettings.json

Add:

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

Do not copy someone else's IDs.

---

# PHASE 17 — Configure Program.cs

## Step 21 — Add authentication

Add:

```csharp
using Microsoft.AspNetCore.Authentication.OpenIdConnect;
using Microsoft.Identity.Web;
using Microsoft.Identity.Web.UI;
```

Then:

```csharp
builder.Services
    .AddAuthentication(OpenIdConnectDefaults.AuthenticationScheme)
    .AddMicrosoftIdentityWebApp(
        builder.Configuration.GetSection("AzureAd"));
```

Add MVC identity UI:

```csharp
builder.Services
    .AddControllersWithViews()
    .AddMicrosoftIdentityUI();
```

And make sure the request pipeline contains:

```csharp
app.UseAuthentication();
app.UseAuthorization();
```

---

# PHASE 18 — Protect the Employee Portal

Add:

```csharp
using Microsoft.AspNetCore.Authorization;
```

Protect the controller:

```csharp
[Authorize]
public class HomeController : Controller
{
    public IActionResult Index()
    {
        return View();
    }
}
```

Now:

```text
User
 ↓
Employee Portal
 ↓
Not authenticated
 ↓
Microsoft Entra ID
 ↓
Username/password
 ↓
MFA if required by tenant/Conditional Access policy
 ↓
/signin-oidc
 ↓
Employee Portal
```

MFA is not produced merely by adding `[Authorize]`; it is enforced when the relevant Entra authentication/Conditional Access policy requires it.

---

# PHASE 19 — Test Windows Entra authentication

Open the application.

Expected behavior:

```text
Employee Portal
      ↓
Microsoft Entra login
      ↓
Enter organization account
      ↓
MFA if required
      ↓
Authentication succeeds
      ↓
Employee Portal opens
```

If you see:

```text
AADSTS50011
```

check the redirect URI.

If you see:

```text
AADSTS700016
```

verify the `ClientId`. Microsoft lists these among the common ASP.NET Core configuration problems. :chatgpt-content-reference{index="5"}

---

# PHASE 20 — Deploy Linux VM

## Step 22 — Linux configuration

Deploy:

```text
Ubuntu 22.04 LTS

Hostname:
linuxapp01

Private IP:
10.2.1.4

Subnet:
10.2.1.0/24
```

Do not assign a public IP.

---

# PHASE 21 — Test Linux connectivity

From your laptop with VPN connected:

```powershell
Test-NetConnection 10.2.1.4 -Port 22
```

Your successful test looked like:

```text
ComputerName     : 10.2.1.4
RemotePort       : 22
InterfaceAlias   : Azure-Hub-Spoke-P2S
SourceAddress    : 172.16.100.2
TcpTestSucceeded : True
```

This proves:

```text
Laptop → VPN → Hub → Peering → Spoke 2 → Linux
```

---

# PHASE 22 — Configure SSH

## Step 23 — Generate PuTTY key

Open:

```text
PuTTYgen
```

Generate an RSA key.

Save:

```text
Public key
Private .ppk key
```

Azure Portal:

```text
Linux VM
→ Reset password
→ Add SSH public key
```

Username:

```text
azureadmin
```

Paste the public key.

---

## Step 24 — Configure PuTTY

Set:

```text
Host:
10.2.1.4

Port:
22

Connection:
SSH
```

Under:

```text
Connection
→ SSH
→ Auth
→ Credentials
```

select the `.ppk` private key.

Login:

```text
azureadmin
```

---

# PHASE 23 — Inspect Linux VM

Run:

```bash
hostname
```

Expected:

```text
linuxapp01
```

Check OS:

```bash
cat /etc/os-release
```

Check Python:

```bash
python3 --version
```

Check ports:

```bash
sudo ss -tulpn
```

Your working system showed:

```text
TCP 22
TCP 5000
```

---

# PHASE 24 — Prepare Flask environment

Go to:

```bash
cd /opt/flaskapp
```

Install venv support:

```bash
sudo apt update
```

```bash
sudo apt install -y python3.10-venv
```

Remove incomplete environment if necessary:

```bash
sudo rm -rf /opt/flaskapp/.venv
```

Create:

```bash
sudo python3 -m venv /opt/flaskapp/.venv
```

Change ownership:

```bash
sudo chown -R azureadmin:azureadmin /opt/flaskapp/.venv
```

Activate:

```bash
source /opt/flaskapp/.venv/bin/activate
```

---

# PHASE 25 — Install Flask + Entra libraries

Run:

```bash
pip install --upgrade pip
```

Then:

```bash
pip install Flask msal python-dotenv requests
```

Verify:

```bash
pip list | grep -Ei "Flask|msal|dotenv|requests"
```

Your lab successfully showed Flask, MSAL, `python-dotenv`, and `requests`.

Microsoft's current Flask tutorial similarly uses Python environment configuration plus Microsoft identity libraries for the web sign-in flow. :chatgpt-content-reference{index="6"}

---

# PHASE 26 — Register Linux App in Entra ID

## Step 26 — Create second App Registration

Go to:

```text
Microsoft Entra ID
→ App registrations
→ New registration
```

Example:

```text
EmployeePortal-Linux
```

Choose:

```text
Accounts in this organizational directory only
```

Register.

Record:

```text
Tenant ID
Client ID
```

---

# PHASE 27 — Configure Linux Web platform

Go to:

```text
Authentication
→ Add platform
→ Web
```

Because your browser accesses the Linux application through a local PuTTY tunnel, use:

```text
http://localhost:5000/getAToken
```

The redirect URI used by the application and the one registered with Entra must be identical.

Microsoft's current Flask tutorial likewise uses a localhost `/getAToken` redirect during local development/testing. :chatgpt-content-reference{index="7"}

---

# PHASE 28 — Create Linux client credential

Go to:

```text
Certificates & secrets
→ Client secrets
→ New client secret
```

Copy the **Value**, not merely the secret ID.

For this lab, store it in `.env`.

Microsoft explicitly warns that client secrets are appropriate for demonstration/tutorial scenarios but recommends certificates or federated credentials instead for production applications. :chatgpt-content-reference{index="8"}

---

# PHASE 29 — Create Linux .env

Run:

```bash
cd /opt/flaskapp
```

Create:

```bash
nano .env
```

Add:

```text
TENANT_ID=<YOUR-TENANT-ID>
CLIENT_ID=<YOUR-CLIENT-ID>
CLIENT_SECRET=<YOUR-NEW-SECRET>
REDIRECT_PATH=/getAToken
```

Save Nano:

```text
Ctrl + O
Enter
Ctrl + X
```

Protect it:

```bash
chmod 600 /opt/flaskapp/.env
```

Never commit:

```text
.env
```

to GitHub.

---

# PHASE 30 — Add Entra authentication to Flask

## Step 30 — app.py

Core configuration:

```python
import os
import secrets
import msal

from flask import Flask, redirect, request, session, url_for
from dotenv import load_dotenv

load_dotenv("/opt/flaskapp/.env")

app = Flask(__name__)
app.secret_key = secrets.token_hex(32)

TENANT_ID = os.getenv("TENANT_ID")
CLIENT_ID = os.getenv("CLIENT_ID")
CLIENT_SECRET = os.getenv("CLIENT_SECRET")

AUTHORITY = f"https://login.microsoftonline.com/{TENANT_ID}"

REDIRECT_URI = "http://localhost:5000/getAToken"
```

Create the MSAL confidential client:

```python
def build_msal_app():
    return msal.ConfidentialClientApplication(
        CLIENT_ID,
        authority=AUTHORITY,
        client_credential=CLIENT_SECRET
    )
```

---

# PHASE 31 — Add login route

```python
@app.route("/login")
def login():

    flow = build_msal_app().initiate_auth_code_flow(
        scopes=[],
        redirect_uri=REDIRECT_URI
    )

    session["flow"] = flow

    return redirect(flow["auth_uri"])
```

---

# PHASE 32 — Add Entra callback

```python
@app.route("/getAToken")
def authorized():

    result = build_msal_app().acquire_token_by_auth_code_flow(
        session.get("flow", {}),
        request.args
    )

    if "error" in result:
        return result.get(
            "error_description",
            "Authentication failed"
        ), 400

    session["user"] = result.get("id_token_claims")

    return redirect(url_for("dashboard"))
```

This implements the authorization-code pattern Microsoft documents for web applications. :chatgpt-content-reference{index="9"}

---

# PHASE 33 — Protect dashboard

```python
@app.route("/dashboard")
def dashboard():

    user = session.get("user")

    if not user:
        return redirect(url_for("login"))

    return f"""
    <html>
    <body>

    <h1>Employee Dashboard</h1>

    <h2>
    Welcome {user.get('name', 'Employee')}
    </h2>

    <p>Authentication: Microsoft Entra ID</p>

    </body>
    </html>
    """
```

---

# PHASE 34 — Keep health endpoint

```python
@app.route("/health")
def health():

    return {
        "status": "healthy",
        "server": "linuxapp01",
        "spoke": "spoke-2"
    }
```

Run Flask on:

```python
app.run(
    host="0.0.0.0",
    port=5000
)
```

---

# PHASE 35 — Test Flask locally

Run:

```bash
curl http://localhost:5000
```

Then:

```bash
curl http://localhost:5000/health
```

Expected:

```json
{
  "server": "linuxapp01",
  "spoke": "spoke-2",
  "status": "healthy"
}
```

Test its private address:

```bash
curl http://10.2.1.4:5000
```

---

# PHASE 36 — Create Linux systemd service

Create:

```bash
sudo nano /etc/systemd/system/flaskapp.service
```

Use:

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

Then:

```bash
sudo systemctl daemon-reload
```

Enable:

```bash
sudo systemctl enable flaskapp
```

Restart:

```bash
sudo systemctl restart flaskapp
```

Check:

```bash
sudo systemctl status flaskapp
```

Your successful service showed:

```text
Active: active (running)

Exec:
 /opt/flaskapp/.venv/bin/python
 /opt/flaskapp/app.py
```

For a production deployment, use a dedicated non-root service account and a production WSGI server rather than Flask's development server.

---

# PHASE 37 — Test from laptop

VPN must be connected.

PowerShell:

```powershell
Test-NetConnection 10.2.1.4 -Port 5000
```

Expected:

```text
SourceAddress    : 172.16.100.2
TcpTestSucceeded : True
```

---

# PHASE 38 — PuTTY local tunnel for Linux Entra login

This is important because your Entra redirect URI is:

```text
http://localhost:5000/getAToken
```

In PuTTY:

```text
Connection
  ↓
SSH
  ↓
Tunnels
```

Set:

```text
Source port:
5000

Destination:
127.0.0.1:5000

Type:
Local
```

Click:

```text
Add
```

You should see:

```text
L5000 127.0.0.1:5000
```

Open the SSH session.

---

# PHASE 39 — Test Linux application login

On your Windows laptop open:

```text
http://localhost:5000
```

Then login.

The flow becomes:

```text
Windows Browser
      ↓
localhost:5000
      ↓
PuTTY SSH tunnel
      ↓
P2S VPN
      ↓
Hub VPN Gateway
      ↓
Spoke 2
      ↓
Linux Flask
      ↓
/login
      ↓
Microsoft Entra ID
      ↓
User credentials
      ↓
MFA if policy requires it
      ↓
http://localhost:5000/getAToken
      ↓
PuTTY tunnel
      ↓
Flask
      ↓
Employee Dashboard
```

That is the complete Linux authentication flow.

---

# PHASE 40 — Final project validation

Run the network tests from Windows:

```powershell
Test-NetConnection 10.2.1.4 -Port 22
Test-NetConnection 10.2.1.4 -Port 5000
```

On Linux:

```bash
hostname
```

```bash
sudo ss -tulpn
```

```bash
curl http://localhost:5000/health
```

```bash
sudo systemctl status flaskapp --no-pager
```

For logs:

```bash
sudo journalctl -u flaskapp -n 50 --no-pager
```

On Windows VMSS:

```powershell
Get-Service W3SVC
```

```powershell
Get-WindowsFeature Web-Server
```

and test the IIS application.

---

# PHASE 41 — What the completed project proves

At the end, you have implemented:

```text
Azure Hub-Spoke Networking
        ↓
VNet Peering
        ↓
Azure Firewall
        ↓
NSGs / Routing
        ↓
Azure VPN Gateway
        ↓
P2S private connectivity
        ↓
Windows Server VMSS
        ↓
IIS
        ↓
ASP.NET Core/.NET
        ↓
Microsoft Entra ID authentication
```

and independently:

```text
Spoke 2
   ↓
Ubuntu Linux
   ↓
SSH private access
   ↓
Python virtual environment
   ↓
Flask
   ↓
systemd
   ↓
MSAL
   ↓
Microsoft Entra ID
```

So the important learning outcome is not simply that you deployed two VMs. You built a **private multi-spoke Azure application architecture with centralized connectivity/security and identity-aware application authentication across both Windows/.NET and Linux/Python stacks**.

One distinction is especially important for anyone reproducing the project: **P2S VPN authentication and application Entra authentication are separate security layers.** The VPN gets the user's device onto the private network; the Entra app registration authenticates the user to the application. Azure also supports Entra authentication for the VPN itself, but that is a different configuration from the certificate-based P2S setup used in this lab. :chatgpt-content-reference{index="10"}

