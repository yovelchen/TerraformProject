resource "azurerm_resource_group" "terraform_flowers_rg" {
  name     = "${var.resource_group_name}${var.project_name}"
  location = "${var.location}"
}

resource "azurerm_virtual_network" "terraform_flowers_vnet" {
  name                = "${var.vnet_name}${var.project_name}"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.terraform_flowers_rg.location
  resource_group_name = azurerm_resource_group.terraform_flowers_rg.name
  depends_on = [
     azurerm_resource_group.terraform_flowers_rg
   ]
}

resource "azurerm_subnet" "web_subnet" {
  name                 = "web${var.subnet_name}"
  resource_group_name  = azurerm_resource_group.terraform_flowers_rg.name
  virtual_network_name = azurerm_virtual_network.terraform_flowers_vnet.name
  address_prefixes     = ["10.0.0.0/24"]
  depends_on = [
    azurerm_virtual_network.terraform_flowers_vnet
   ]
}

output "web_subnet_name" {
  value = azurerm_subnet.web_subnet.name
}

resource "azurerm_subnet" "db_subnet" {
  name                 = "db${var.subnet_name}"
  resource_group_name  = azurerm_resource_group.terraform_flowers_rg.name
  virtual_network_name = azurerm_virtual_network.terraform_flowers_vnet.name
  address_prefixes     = ["10.0.1.0/24"]
  depends_on = [
    azurerm_virtual_network.terraform_flowers_vnet
    ]
}

output "db_subnet_name" {
  value = azurerm_subnet.db_subnet.name
}

resource "azurerm_network_security_group" "terraform_flowers_web_nsg" {
  name                = "${var.nsg_name}web-${var.project_name}"
  location            = azurerm_resource_group.terraform_flowers_rg.location
  resource_group_name = azurerm_resource_group.terraform_flowers_rg.name

  security_rule {
    name                       = "Allow-Inbound-8080"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "10.0.0.0/24"
  }

  security_rule {
    name                       = "Allow-Web-Inbound-SSH"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "10.0.0.0/24"
  }
}

resource "azurerm_network_security_group" "terraform_flowers_db_nsg" {
  name                = "${var.nsg_name}db-${var.project_name}"
  location            = azurerm_resource_group.terraform_flowers_rg.location
  resource_group_name = azurerm_resource_group.terraform_flowers_rg.name

  security_rule {
    name                       = "Allow-DB-Inbound-5432"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5432"
    source_address_prefix      = "10.0.0.0/24"
    destination_address_prefix = "10.0.1.0/24"
  }

  security_rule {
    name                       = "Allow-Web-Inbound-SSH"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "10.0.0.0/24"
    destination_address_prefix = "10.0.1.0/24"
  }
}

resource "azurerm_subnet_network_security_group_association" "nsg_web_subnet_association" {
  subnet_id                 = azurerm_subnet.web_subnet.id
  network_security_group_id = azurerm_network_security_group.terraform_flowers_web_nsg.id
}

resource "azurerm_subnet_network_security_group_association" "nsg_db_subnet_association" {
  subnet_id                 = azurerm_subnet.db_subnet.id
  network_security_group_id = azurerm_network_security_group.terraform_flowers_db_nsg.id
}

resource "azurerm_public_ip" "web1_public_ip" {
  name                = "web1-public-ip"
  resource_group_name = azurerm_resource_group.terraform_flowers_rg.name
  location            = azurerm_resource_group.terraform_flowers_rg.location
  allocation_method   = "Dynamic"
}

resource "azurerm_public_ip" "web2_public_ip" {
  name                = "web2-public-ip"
  resource_group_name = azurerm_resource_group.terraform_flowers_rg.name
  location            = azurerm_resource_group.terraform_flowers_rg.location
  allocation_method   = "Dynamic"
}

resource "azurerm_public_ip" "db_public_ip" {
  name                = "db-public-ip"
  resource_group_name = azurerm_resource_group.terraform_flowers_rg.name
  location            = azurerm_resource_group.terraform_flowers_rg.location
  allocation_method   = "Dynamic"
}


# Create network interface for web vm
resource "azurerm_network_interface" "webVM1_nic" {
  name                = "webVM1_NIC"
  location            = azurerm_resource_group.terraform_flowers_rg.location
  resource_group_name = azurerm_resource_group.terraform_flowers_rg.name
  ip_configuration {
    name                          = "internal_web_nic_configuration"
    subnet_id                     = azurerm_subnet.web_subnet.id
    public_ip_address_id          = azurerm_public_ip.web1_public_ip.id
    private_ip_address_allocation = "Dynamic"
  }
  depends_on = [ 
    azurerm_virtual_network.terraform_flowers_vnet,
    azurerm_subnet.web_subnet
   ]
}

resource "azurerm_network_interface" "webVM2_nic" {
  name                = "webVM2_NIC"
  location            = azurerm_resource_group.terraform_flowers_rg.location
  resource_group_name = azurerm_resource_group.terraform_flowers_rg.name
  ip_configuration {
    name                          = "internal_web2_nic_configuration"
    subnet_id                     = azurerm_subnet.web_subnet.id
    public_ip_address_id          = azurerm_public_ip.web2_public_ip.id
    private_ip_address_allocation = "Dynamic"
  }
  depends_on = [ 
    azurerm_virtual_network.terraform_flowers_vnet,
    azurerm_subnet.web_subnet
   ]
}

resource "azurerm_network_interface" "db_terraform_nic" {
  name                = "${var.db_nic}" # add variable
  location            = azurerm_resource_group.terraform_flowers_rg.location
  resource_group_name = azurerm_resource_group.terraform_flowers_rg.name
  ip_configuration {
    name                          = "db-nic-configuration"
    public_ip_address_id          = azurerm_public_ip.db_public_ip.id
    subnet_id                     = azurerm_subnet.db_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}


resource "tls_private_key" "web_ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "web1_public_key" {
  filename = "C:\\Users\\yovel\\Final_project\\web1_key.pem"
  content = tls_private_key.web_ssh.private_key_pem
}

resource "tls_private_key" "web2_ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
  }

resource "local_file" "web2_public_key" {
  filename = "C:\\Users\\yovel\\Final_project\\web2_key.pem"
  content = tls_private_key.web2_ssh.private_key_pem
}

resource "tls_private_key" "db_ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
  }

resource "local_file" "db_public_key" {
  filename = "C:\\Users\\yovel\\Final_project\\db_key.pem"
  content = tls_private_key.db_ssh.private_key_pem
}

resource "azurerm_linux_virtual_machine" "web1_terraform_vm" {
  name                  = "mywebVM1"
  location              = azurerm_resource_group.terraform_flowers_rg.location
  resource_group_name   = azurerm_resource_group.terraform_flowers_rg.name
  network_interface_ids = [
    azurerm_network_interface.webVM1_nic.id
    ]
  size                  = "Standard_D2s_v3"


  os_disk {
    name                 = "web_os_disk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  computer_name                   = "mywebvm"
  admin_username                  = "azureuser"
  disable_password_authentication = true

  admin_ssh_key {
    username   = "azureuser"
    public_key = tls_private_key.web_ssh.public_key_openssh
  }
}

resource "azurerm_virtual_machine_extension" "web_user_data_script" {
  name                 = "web_user_data_script"
  virtual_machine_id   = azurerm_linux_virtual_machine.web1_terraform_vm.id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.1"

  

  settings = <<SETTINGS
    {
      "script": "${base64encode(file("${path.module}/scripts/webuserdata.sh"))}"
    
    }
SETTINGS
  depends_on = [
    azurerm_virtual_machine_data_disk_attachment.disk_attachment,
    azurerm_linux_virtual_machine.web1_terraform_vm,
  ]
}

resource "azurerm_linux_virtual_machine" "web2_terraform_vm" {
  name                  = "mywebVM2"
  location              = azurerm_resource_group.terraform_flowers_rg.location
  resource_group_name   = azurerm_resource_group.terraform_flowers_rg.name
  network_interface_ids = [
    azurerm_network_interface.webVM2_nic.id
    ]
  size                  = "Standard_D2s_v3"

  os_disk {
    name                 = "web2_os_disk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  computer_name                   = "mywebvm2"
  admin_username                  = "azureuser"
  disable_password_authentication = true

  admin_ssh_key {
    username   = "azureuser"
    public_key = tls_private_key.web2_ssh.public_key_openssh
  }
}



# Creating a data disk for postgres
resource "azurerm_managed_disk" "db_external_disk" {
  name                 = "db_data_disk"
  location             = azurerm_resource_group.terraform_flowers_rg.location
  resource_group_name  = azurerm_resource_group.terraform_flowers_rg.name
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = "10"
}

# Creating a linux virtual machine
resource "azurerm_linux_virtual_machine" "db_vm" {
  name                  = "${var.db_vm_name}-${var.project_name}"
  resource_group_name   = azurerm_resource_group.terraform_flowers_rg.name
  location              = azurerm_resource_group.terraform_flowers_rg.location
  network_interface_ids = [azurerm_network_interface.db_terraform_nic.id]
  size                  = "Standard_DS1_v2"
  admin_username        = "azureuser"
  computer_name         = "db-vm"
  disable_password_authentication = true
    
  admin_ssh_key {
    username   = "azureuser"
    public_key = tls_private_key.db_ssh.public_key_openssh
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  os_disk {
    name                 = "db_os_disk"
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }

}  

# Attaching the data disk to the Linux VM
resource "azurerm_virtual_machine_data_disk_attachment" "disk_attachment" {
  managed_disk_id    = azurerm_managed_disk.db_external_disk.id
  virtual_machine_id = azurerm_linux_virtual_machine.db_vm.id
  lun                = "10"
  caching            = "ReadWrite"
}

resource "azurerm_virtual_machine_extension" "user_data_script" {
  name                 = "user_data_script"
  virtual_machine_id   = azurerm_linux_virtual_machine.db_vm.id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.1"

  

  settings = <<SETTINGS
    {
      "script": "${base64encode(file("${path.module}/scripts/userdata.sh"))}"
    
    }
SETTINGS
  depends_on = [
    azurerm_virtual_machine_data_disk_attachment.disk_attachment,
    azurerm_linux_virtual_machine.db_vm ,
  ]
}
