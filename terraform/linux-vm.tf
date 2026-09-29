# ============================================================
# SPOKE 2 - LINUX APPLICATION VM
# ============================================================

resource "azurerm_network_interface" "linux_app_nic" {
  name                = "${var.project_name}-linux-app-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.spoke2_linux_subnet.id
    private_ip_address_allocation = "Dynamic"
  }

  tags = {
    Project     = "Azure Hub Spoke Lab"
    Environment = "Lab"
    Tier        = "Application"
    ManagedBy   = "Terraform"
  }
}

resource "azurerm_linux_virtual_machine" "linux_app" {
  name                = "${var.project_name}-linux-app"
  computer_name       = "linuxapp01"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  size = "Standard_B1s"

  admin_username                  = "azureadmin"
  disable_password_authentication = true

  network_interface_ids = [
    azurerm_network_interface.linux_app_nic.id
  ]

  admin_ssh_key {
    username   = "azureadmin"
    public_key = file("${path.module}/id_rsa.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  custom_data = base64encode(<<-EOF
    #!/bin/bash

    apt-get update -y
    apt-get install -y python3 python3-pip

    mkdir -p /opt/flaskapp

    cat > /opt/flaskapp/app.py <<'PYTHON'
    from flask import Flask
    import socket

    app = Flask(__name__)

    @app.route("/")
    def home():
        return """
        <html>
        <body>
        <h1>Azure Hub-Spoke Project</h1>
        <h2>Spoke-2 Linux Application</h2>
        <p>Server: %s</p>
        <p>Application: Python Flask</p>
        <p>Status: Healthy</p>
        </body>
        </html>
        """ % socket.gethostname()

    @app.route("/health")
    def health():
        return {
            "status": "healthy",
            "server": socket.gethostname(),
            "spoke": "spoke-2"
        }

    app.run(host="0.0.0.0", port=5000)
    PYTHON

    pip3 install flask

    cat > /etc/systemd/system/flaskapp.service <<'SERVICE'
    [Unit]
    Description=Azure Hub Spoke Flask Application
    After=network.target

    [Service]
    User=root
    WorkingDirectory=/opt/flaskapp
    ExecStart=/usr/bin/python3 /opt/flaskapp/app.py
    Restart=always

    [Install]
    WantedBy=multi-user.target
    SERVICE

    systemctl daemon-reload
    systemctl enable flaskapp
    systemctl start flaskapp
  EOF
  )

  tags = {
    Project     = "Azure Hub Spoke Lab"
    Environment = "Lab"
    Tier        = "Application"
    OS          = "Linux"
    ManagedBy   = "Terraform"
  }
}