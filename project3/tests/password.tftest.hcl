# Offline test with a mocked azurerm provider (random runs for real).
# Run: tofu init -backend=false && tofu test   (or terraform test, 1.7+)

mock_provider "azurerm" {
  mock_data "azurerm_resource_group" {
    defaults = {
      id       = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg"
      location = "centralindia"
    }
  }
  mock_data "azurerm_client_config" {
    defaults = {
      tenant_id = "00000000-0000-0000-0000-000000000001"
      object_id = "00000000-0000-0000-0000-000000000002"
    }
  }
  mock_resource "azurerm_key_vault" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.KeyVault/vaults/dev-kv-abc123"
    }
  }
  mock_resource "azurerm_subnet" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Network/virtualNetworks/dev-vnet/subnets/dev-subnet"
    }
  }
  mock_resource "azurerm_network_interface" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Network/networkInterfaces/dev-nic"
    }
  }
}

run "password_is_generated_and_stored_in_key_vault" {
  command = apply

  assert {
    condition     = length(random_password.vm_admin.result) == 24
    error_message = "Password should be 24 characters."
  }

  assert {
    condition     = random_password.vm_admin.result != "P@ssw0rd1234!"
    error_message = "The old hardcoded password must not be used."
  }

  assert {
    condition     = azurerm_key_vault_secret.vm_admin_password.value == random_password.vm_admin.result
    error_message = "Key Vault secret must hold the generated password."
  }

  assert {
    condition     = azurerm_key_vault.kv.rbac_authorization_enabled
    error_message = "Key Vault should use RBAC."
  }
}

run "rejects_vm_size_not_in_allowed_list" {
  command = plan

  variables {
    vm_config = {
      size      = "Standard_E64s_v5"
      publisher = "Canonical"
      offer     = "0001-com-ubuntu-server-jammy"
      sku       = "22_04-lts"
      version   = "latest"
    }
  }

  expect_failures = [azurerm_virtual_machine.vm]
}
