# Offline tests with a mocked azurerm provider (random runs for real).
# Run: tofu init -backend=false && tofu test

# Mocked computed values are random strings. Resource IDs are parsed by the
# provider, so give every referenced resource a well-formed ID.
mock_provider "azurerm" {
  mock_data "azurerm_client_config" {
    defaults = {
      tenant_id = "00000000-0000-0000-0000-000000000001"
      object_id = "00000000-0000-0000-0000-000000000002"
    }
  }
  mock_resource "azurerm_resource_group" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-data-dev"
    }
  }
  mock_resource "azurerm_virtual_network" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-data-dev/providers/Microsoft.Network/virtualNetworks/vnet-data-dev"
    }
  }
  mock_resource "azurerm_subnet" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-data-dev/providers/Microsoft.Network/virtualNetworks/vnet-data-dev/subnets/snet-mock"
    }
  }
  mock_resource "azurerm_network_security_group" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-data-dev/providers/Microsoft.Network/networkSecurityGroups/nsg-mock"
    }
  }
  mock_resource "azurerm_private_dns_zone" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-data-dev/providers/Microsoft.Network/privateDnsZones/data-dev.private.postgres.database.azure.com"
    }
  }
  mock_resource "azurerm_key_vault" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-data-dev/providers/Microsoft.KeyVault/vaults/kv-data-dev-abcde"
    }
  }
  mock_resource "azurerm_postgresql_flexible_server" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-data-dev/providers/Microsoft.DBforPostgreSQL/flexibleServers/psql-data-dev-abcde"
    }
  }
  mock_resource "azurerm_network_interface" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-data-dev/providers/Microsoft.Network/networkInterfaces/nic-data-dev-vm"
    }
  }
  mock_resource "azurerm_linux_virtual_machine" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-data-dev/providers/Microsoft.Compute/virtualMachines/vm-data-dev-test"
    }
  }
  mock_resource "azurerm_recovery_services_vault" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-data-dev/providers/Microsoft.RecoveryServices/vaults/rsv-data-dev"
    }
  }
  mock_resource "azurerm_backup_policy_vm" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-data-dev/providers/Microsoft.RecoveryServices/vaults/rsv-data-dev/backupPolicies/bkpol-data-dev-vm-daily"
    }
  }
  mock_resource "azurerm_role_definition" {
    defaults = {
      id                          = "/subscriptions/00000000-0000-0000-0000-000000000000/providers/Microsoft.Authorization/roleDefinitions/11111111-1111-1111-1111-111111111111|/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-data-dev"
      role_definition_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/providers/Microsoft.Authorization/roleDefinitions/11111111-1111-1111-1111-111111111111"
    }
  }
}

# Throw-away public key generated for the tests; the private key was deleted.
variables {
  admin_ssh_public_key       = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIE8JPWDAoMhvnQYRwPLGPzuolyMMB6VqCPh3Cr7mPGRV test-only"
  entra_admin_object_id      = "aaaaaaaa-0000-0000-0000-000000000001"
  entra_admin_principal_name = "pg-admins"
  operators_group_object_id  = "bbbbbbbb-0000-0000-0000-000000000002"
}

run "private_server_backups_and_least_privilege_role" {
  command = apply

  # PostgreSQL: private access only, Entra ID on, backups as configured.
  assert {
    condition     = azurerm_postgresql_flexible_server.this.public_network_access_enabled == false
    error_message = "PostgreSQL must not have public network access."
  }
  assert {
    condition     = azurerm_postgresql_flexible_server.this.delegated_subnet_id == azurerm_subnet.postgres.id && azurerm_postgresql_flexible_server.this.private_dns_zone_id == azurerm_private_dns_zone.postgres.id
    error_message = "PostgreSQL must use the delegated subnet and the private DNS zone."
  }
  assert {
    condition     = endswith(azurerm_private_dns_zone.postgres.name, ".postgres.database.azure.com")
    error_message = "The PostgreSQL private DNS zone must end in .postgres.database.azure.com."
  }
  assert {
    condition     = one(azurerm_subnet.postgres.delegation).service_delegation[0].name == "Microsoft.DBforPostgreSQL/flexibleServers"
    error_message = "The postgres subnet must be delegated to Flexible Server."
  }
  assert {
    condition     = azurerm_postgresql_flexible_server.this.authentication[0].active_directory_auth_enabled
    error_message = "Entra ID authentication must be on."
  }
  assert {
    condition     = azurerm_postgresql_flexible_server_active_directory_administrator.this.principal_type == "Group"
    error_message = "The Entra ID admin should be a group by default."
  }
  assert {
    condition     = azurerm_postgresql_flexible_server.this.backup_retention_days == 14 && azurerm_postgresql_flexible_server.this.geo_redundant_backup_enabled == false
    error_message = "Default backup retention is 14 days, geo-redundant off."
  }
  assert {
    condition     = azurerm_postgresql_flexible_server_configuration.this["require_secure_transport"].value == "on"
    error_message = "require_secure_transport must be on."
  }

  # Password: generated, stored in Key Vault, Key Vault private only.
  assert {
    condition     = azurerm_key_vault_secret.postgres_admin_password.value == random_password.postgres_admin.result && length(random_password.postgres_admin.result) == 32
    error_message = "Key Vault must hold the generated 32-character password."
  }
  assert {
    condition     = azurerm_postgresql_flexible_server.this.administrator_password == random_password.postgres_admin.result
    error_message = "The server must use the generated password."
  }
  assert {
    condition     = azurerm_key_vault.this.public_network_access_enabled == false && azurerm_key_vault.this.network_acls[0].default_action == "Deny"
    error_message = "With no allowed IPs, Key Vault public access must be off."
  }
  assert {
    condition     = azurerm_private_endpoint.key_vault.private_service_connection[0].subresource_names == tolist(["vault"])
    error_message = "Key Vault private endpoint must target the vault sub-resource."
  }

  # Azure Backup: daily policy with retention tiers, protecting the test VM.
  assert {
    condition     = azurerm_backup_policy_vm.daily.backup[0].frequency == "Daily" && azurerm_backup_policy_vm.daily.retention_daily[0].count == 14
    error_message = "Backup must be daily with 14 daily points."
  }
  assert {
    condition     = length(azurerm_backup_policy_vm.daily.retention_weekly) == 1 && length(azurerm_backup_policy_vm.daily.retention_monthly) == 1 && length(azurerm_backup_policy_vm.daily.retention_yearly) == 1
    error_message = "Weekly, monthly and yearly retention must be set by default."
  }
  assert {
    condition     = azurerm_backup_protected_vm.test.source_vm_id == azurerm_linux_virtual_machine.test.id && azurerm_backup_protected_vm.test.backup_policy_id == azurerm_backup_policy_vm.daily.id
    error_message = "The test VM must be protected by the daily policy."
  }

  # Custom role: least privilege, scoped to the resource group, assigned to the group.
  assert {
    condition     = contains(azurerm_role_definition.vm_operator.permissions[0].actions, "Microsoft.Compute/virtualMachines/restart/action")
    error_message = "The custom role must allow VM restart."
  }
  assert {
    condition = alltrue([
      for a in azurerm_role_definition.vm_operator.permissions[0].actions :
      !strcontains(a, "*") && !endswith(a, "/write") && !endswith(a, "/delete")
    ])
    error_message = "The custom role must not have wildcards, write or delete actions."
  }
  assert {
    condition     = azurerm_role_definition.vm_operator.assignable_scopes == tolist([azurerm_resource_group.this.id])
    error_message = "The custom role must only be assignable in this resource group."
  }
  assert {
    condition     = azurerm_role_assignment.operators.principal_id == "bbbbbbbb-0000-0000-0000-000000000002" && azurerm_role_assignment.operators.principal_type == "Group"
    error_message = "The role must be assigned to the operators group."
  }
}

run "geo_backup_and_key_vault_ip_allow_list" {
  command = plan

  variables {
    geo_redundant_backup_enabled = true
    key_vault_allowed_ips        = ["203.0.113.10"]
  }

  assert {
    condition     = azurerm_postgresql_flexible_server.this.geo_redundant_backup_enabled
    error_message = "geo_redundant_backup_enabled should flow into the server."
  }
  assert {
    condition     = azurerm_key_vault.this.public_network_access_enabled && azurerm_key_vault.this.network_acls[0].ip_rules == toset(["203.0.113.10"])
    error_message = "An allowed IP should open the Key Vault firewall for that IP only."
  }
}

run "yearly_retention_can_be_turned_off" {
  command = plan

  variables {
    vm_backup = {
      time    = "02:30"
      daily   = 7
      weekly  = 4
      monthly = 6
      yearly  = 0
    }
  }

  assert {
    condition     = length(azurerm_backup_policy_vm.daily.retention_yearly) == 0
    error_message = "yearly = 0 must remove the yearly retention block."
  }
}

run "rejects_retention_over_35_days" {
  command = plan

  variables {
    backup_retention_days = 40
  }

  expect_failures = [var.backup_retention_days]
}

run "rejects_group_id_that_is_not_a_guid" {
  command = plan

  variables {
    operators_group_object_id = "platform-operators"
  }

  expect_failures = [var.operators_group_object_id]
}

run "rejects_reserved_admin_login" {
  command = plan

  variables {
    postgres_admin_login = "azure_superuser"
  }

  expect_failures = [var.postgres_admin_login]
}

run "rejects_cross_region_restore_without_grs" {
  command = plan

  variables {
    vault_storage_mode           = "LocallyRedundant"
    cross_region_restore_enabled = true
  }

  expect_failures = [azurerm_recovery_services_vault.this]
}
