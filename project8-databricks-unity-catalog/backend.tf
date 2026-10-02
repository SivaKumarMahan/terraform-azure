# Remote state in Azure Storage, partial configuration.
# The real values live in backend.hcl (git-ignored). Copy backend.hcl.example first:
#   cp backend.hcl.example backend.hcl
#   tofu init -backend-config=backend.hcl
# For offline checks use: tofu init -backend=false
terraform {
  backend "azurerm" {}
}
