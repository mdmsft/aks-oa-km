resource "azurerm_linux_virtual_machine_scale_set" "main" {
  name                            = "vmss-${local.resource_suffix}"
  resource_group_name             = azurerm_resource_group.main.name
  location                        = azurerm_resource_group.main.location
  sku                             = var.agent_sku
  instances                       = var.agent_instances
  admin_username                  = var.agent_admin_username
  admin_password                  = var.agent_admin_password
  disable_password_authentication = false
  custom_data                     = base64encode(templatefile("${path.module}/cloud-config.yml", {}))
  single_placement_group          = false
  overprovision                   = false
  platform_fault_domain_count     = 1

  identity {
    type = "SystemAssigned"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts-gen2"
    version   = "latest"
  }

  network_interface {
    name    = "nic-${local.resource_suffix}-vms"
    primary = true

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
