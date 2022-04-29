resource "azurerm_linux_virtual_machine_scale_set" "main" {
  name                = "vmss-${local.resource_suffix}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = var.agent_sku
  instances           = var.agent_instances
  admin_username      = var.agent_admin_username

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts-gen2"
    version   = "latest"
  }

  network_interface {
    name = "nic-${local.resource_suffix}-vms"
    ip_configuration {
      name      = "primary"
      primary   = true
      subnet_id = azurerm_subnet.agents.id
    }
  }

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }
}
