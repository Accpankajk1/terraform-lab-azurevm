variable "resourcename" {
  default = "myResourceGroup"
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
    subscription_id = "bb79eb9b-be24-4065-a428-d9b7272db78c"
    client_id       = "447bb515-97a9-46bf-80b8-7727bb236d0b"
    client_secret   = "f77c0535-a42e-4edd-918b-e35022a0455b"
    tenant_id       = "116e9905-19fc-428e-93d4-bcaffb833597"
}

# Create a resource group if it doesn’t exist
resource "azurerm_resource_group" "myterraform" {
    name     = "myResourceGroup"
    location = "West US"

    tags {
        environment = "Terraform Demo"
    }
}

# Create virtual network
resource "azurerm_virtual_network" "myterraformnetwork" {
    name                = "myVnet"
    address_space       = ["10.0.0.0/16"]
    location            = "West US"
    resource_group_name = "${azurerm_resource_group.myterraform.name}"

    tags {
        environment = "Terraform Demo"
    }
}

# Create subnet
resource "azurerm_subnet" "myterraformsubnet" {
    name                 = "mySubnet"
    resource_group_name  = "${azurerm_resource_group.myterraform.name}"
    virtual_network_name = "${azurerm_virtual_network.myterraformnetwork.name}"
    address_prefix       = "10.0.1.0/24"
}

# Create public IPs
resource "azurerm_public_ip" "myterraformpublicip" {
    name                         = "myPublicIP"
    location                     = "West US"
    resource_group_name          = "${azurerm_resource_group.myterraform.name}"
    public_ip_address_allocation = "dynamic"

    tags {
        environment = "Terraform Demo"
    }
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "myterraformnsg" {
    name                = "myNetworkSecurityGroup"
    location            = "West US"
    resource_group_name = "${azurerm_resource_group.myterraform.name}"

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

    tags {
        environment = "Terraform Demo"
    }
}

# Create network interface
resource "azurerm_network_interface" "myterraformnic" {
    name                      = "myNIC"
    location                  = "West US"
    resource_group_name       = "${azurerm_resource_group.myterraform.name}"
    network_security_group_id = "${azurerm_network_security_group.myterraformnsg.id}"

    ip_configuration {
        name                          = "myNicConfiguration"
        subnet_id                     = "${azurerm_subnet.myterraformsubnet.id}"
        private_ip_address_allocation = "dynamic"
        public_ip_address_id          = "${azurerm_public_ip.myterraformpublicip.id}"
    }

    tags {
        environment = "Terraform Demo"
    }
}

# Generate random text for a unique storage account name
resource "random_id" "randomId" {
    keepers = {
        # Generate a new ID only when a new resource group is defined
        resource_group = "${azurerm_resource_group.myterraform.name}"
    }

    byte_length = 8
}

# Create storage account for boot diagnostics
resource "azurerm_storage_account" "mystorageaccount" {
    name                = "diag${random_id.randomId.hex}"
    resource_group_name = "${azurerm_resource_group.myterraform.name}"
    location            = "West US"
    account_tier        = "Standard"
    account_replication_type    = "LRS"

    tags {
        environment = "Terraform Demo"
    }
}

# Create virtual machine
resource "azurerm_virtual_machine" "myterraformvm" {
    name                  = "myVM"
    location              = "West US"
    resource_group_name   = "${azurerm_resource_group.myterraform.name}"
    network_interface_ids = ["${azurerm_network_interface.myterraformnic.id}"]
    vm_size               = "Standard_A0"

    storage_os_disk {
        name              = "myOsDisk"
        caching           = "ReadWrite"
        create_option     = "FromImage"
        managed_disk_type = "Standard_LRS"
    }

    storage_image_reference {
        publisher = "Canonical"
        offer     = "UbuntuServer"
        sku       = "16.04.0-LTS"
        version   = "latest"
    }

    os_profile {
        computer_name  = "myvm"
        admin_username = "azureuser"
    }

    os_profile_linux_config {
        disable_password_authentication = true
        ssh_keys {
            path     = "/home/azureuser/.ssh/authorized_keys"
            key_data = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDIU5YLsVzF9kEqco1QW7cPxciqmQq/wWmEKu/VLj8neLYZsg5GkdDRDjhGjjRC/EvoZi354fZ/kWuX2dhjZ6JT2L7pwIPF1y9PaCcqn2ZZcy4AO0EWX+P8OGxKTX4VhZ+iQYZf7459yHUKuROlzmp2yjxnFYB9hwMHIMqQqHbQ82YFDXFs9KG5B8uevP0VpSJIhjgiTqd2AQXvjlUUxNtHp28rMlHoSDjCzXQumw+iOh9kejj+bhqgrxRFpu/12eEYkacngAihlB58bhBMdEgRjnF4VBiDmgQuiosqWk91G3xtwzUIXSCaN2e+k+AO9dy5R3h7kbg44wHtfFvMU/H57tLWC6PkLbw6QGsWpVn54JUgvaD8+p0bpJxQjgN8CD0ZuhMjByg8m3z+ko0/gHeK0uKzSRiOzRo0C9p8bpsv2sp4roY77/0uUkQYwwLRNS8S+55pQuLfmfaEg+RIQd2yVUdn4OYBWvZwxq7dML0R6NXit5WI5lcN3jJvb0zYQgsAWtSeD2wyAcyFZ7BjykbnFQXvA3g0uhc3jyZf3NLpnX+8tAi5ID0DgNSPFH8bv9+QLcBLZpK0RiURtGxOtTXBHr3x4StxHyMlGCEtvvR8KOZFXS0WKuPgdD3K1971Scm1s8EV69JCWOsFCyzEy1VDfoAru5s9ar31PVAYnwLC5Q== ian@Redapt-323"
        }
    }

    boot_diagnostics {
        enabled = "true"
        storage_uri = "${azurerm_storage_account.mystorageaccount.primary_blob_endpoint}"
    }

    tags {
        environment = "Terraform Demo"
    }
}