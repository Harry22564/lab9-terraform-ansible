terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {}

  subscription_id = "081e00e6-d6d3-48f4-86a4-d039c379c3c9"
  resource_provider_registrations = "none"
}

resource "azurerm_resource_group" "lab9" {
  name     = "LAB9-RG"
  location = "francecentral"
}

resource "azurerm_virtual_network" "vnet" {
  name                = "lab9-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.lab9.location
  resource_group_name = azurerm_resource_group.lab9.name
}

resource "azurerm_subnet" "subnet" {
  name                 = "lab9-subnet"
  resource_group_name  = azurerm_resource_group.lab9.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_public_ip" "pip" {
  name                = "lab9-public-ip"
  location            = azurerm_resource_group.lab9.location
  resource_group_name = azurerm_resource_group.lab9.name
  allocation_method   = "Static"
}

resource "azurerm_network_security_group" "nsg" {
  name                = "lab9-nsg"
  location            = azurerm_resource_group.lab9.location
  resource_group_name = azurerm_resource_group.lab9.name

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "HTTP"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface" "nic" {
  name                = "lab9-nic"
  location            = azurerm_resource_group.lab9.location
  resource_group_name = azurerm_resource_group.lab9.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip.id
  }
}

resource "azurerm_network_interface_security_group_association" "nsg_assoc" {
  network_interface_id      = azurerm_network_interface.nic.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}
resource "azurerm_linux_virtual_machine" "vm" {
  name                = "lab9-vm"
  resource_group_name = azurerm_resource_group.lab9.name
  location            = azurerm_resource_group.lab9.location
  size                = "Standard_D2s_v3"

  admin_username = "azureuser"

  network_interface_ids = [
    azurerm_network_interface.nic.id
  ]

  admin_ssh_key {
    username   = "azureuser"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }

  disable_password_authentication = true
}
