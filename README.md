# terraform-azure

Terraform and OpenTofu projects on Azure. Each folder is a small, separate project with its own state and its own README. They go from language basics (variables, meta-arguments, lifecycle, expressions, functions) to modules with remote state, AKS with ACR, a WAF-protected autoscaling VM Scale Set, and a private PostgreSQL server with Azure Backup and a custom RBAC role.

## Projects

| Folder | What it shows | Main tools | Status |
| --- | --- | --- | --- |
| [project1](project1/README.md) | Network and VM modules, remote state in Azure Storage, importing the state account | Terraform modules, azurerm backend, `terraform import` | Static checks only |
| [project2](project2/README.md) | AKS + ACR with `AcrPull` for the kubelet identity, Flask app, Kubernetes manifests | AKS, ACR, Docker, kubectl | Static checks only |
| [project3](project3/README.md) | All variable types, resource group lock, VM password from `random_password` stored in Key Vault | Key Vault (RBAC), `random_password`, management locks, `tofu test` | Static checks only |
| [project4](project4/README.md) | `count` vs `for_each` vs `for` with storage accounts | Meta-arguments | Static checks only |
| [project5](project5/README.md) | `lifecycle`: `create_before_destroy`, `prevent_destroy`, `ignore_changes`, `precondition` | Lifecycle rules | Static checks only |
| [project6](project6/README.md) | `dynamic` blocks from locals, conditional names, splat outputs | NSG, expressions | Static checks only |
| [project7](project7/README.md) | 11 function assignments (`merge`, `substr`, `lookup`, `toset`, `formatdate`, ...) | Built-in functions, validations | Static checks only |
| [project8-appgw-waf-vmss-autoscale](project8-appgw-waf-vmss-autoscale/README.md) | Application Gateway v2 + WAF policy (OWASP, Prevention) in front of a zonal Linux VMSS; CPU/memory autoscale, rolling upgrades, automatic repair, boot diagnostics, Log Analytics, metric alerts to an Action Group | App Gateway WAF_v2, VMSS, cloud-init, Azure Monitor, NAT gateway, `tofu test` | Static checks only |
| [project9-postgresql-private-backup-rbac](project9-postgresql-private-backup-rbac/README.md) | PostgreSQL Flexible Server with private access and Entra ID admin, password in Key Vault (private endpoint), point-in-time restore + geo-backup option, Recovery Services Vault VM backup policy, least-privilege custom role for an Entra group | PostgreSQL Flexible Server, Private DNS, Key Vault, Azure Backup, custom RBAC, `tofu test` | Static checks only |

"Static checks only" means `fmt`, `init -backend=false`, `validate` and, where there is a `tests/` folder, `tofu test` with mocked providers. Nothing was deployed to Azure in the review. See the "Tested" section of each README for the exact commands and results.

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install) 1.5+ or [OpenTofu](https://opentofu.org/docs/intro/install/) 1.6+
- [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli), logged in with `az login`
- An Azure subscription. Most projects expect an existing resource group `test-rg`
- For projects 3-9: a state storage account `tfstatestorage759` with a container `tfstate` in `test-rg` (project1 uses `tfstatestorage749`)
- For project2: `kubectl` and Docker
- Projects 8 and 9 create their own resource group. They need a region with availability zones. Project 9 also needs two Entra ID groups and rights to create custom roles (Owner or User Access Administrator)

## How to use

Every project is used the same way:

```bash
az login
export ARM_SUBSCRIPTION_ID=$(az account show --query id -o tsv)

cd project4
terraform init
terraform plan
terraform apply
terraform destroy
```

The subscription is not written in the code. Each provider block uses `var.subscription_id`, which is `null` by default, so the provider reads `ARM_SUBSCRIPTION_ID` (or the `az login` default).

Offline checks, no Azure login needed:

```bash
cd project3
terraform fmt -check -recursive
terraform init -backend=false
terraform validate
terraform test     # only in projects with a tests/ folder (project3, project8, project9)
```

### State keys

Each project writes its own state blob, for example `project4/terraform.tfstate`. Projects 4-7 used to share `terraform.tfstate` in the same container, which means one project would plan to destroy the resources of another. If you applied them before this change, run `terraform init -migrate-state` once in each of those folders.

### Lock files

`.terraform.lock.hcl` is git-ignored. The projects are run with both `terraform` and `tofu`, and a lock file only matches the registry of the tool that created it (`registry.terraform.io` vs `registry.opentofu.org`). Versions are pinned with `~>` in `required_providers` instead. If you settle on one tool, commit the lock file and add hashes for every platform with `terraform providers lock -platform=linux_amd64 -platform=darwin_arm64`.

## Repo layout

```text
terraform-azure/
├── project1/                          modules: network + vm, remote state
│   └── modules/{network,vm}/
├── project2/                          AKS + ACR
│   ├── app/                           Flask app + Dockerfile
│   └── k8s/                           Deployment + Service
├── project3/                          variable types, lock, Key Vault password
│   └── tests/
├── project4/                          count / for_each / for
├── project5/                          lifecycle rules
├── project6/                          dynamic blocks, conditionals, splat
├── project7/                          functions
├── project8-appgw-waf-vmss-autoscale/ App Gateway WAF + VMSS autoscale
│   ├── scripts/                       web server + cloud-init template
│   └── tests/
├── project9-postgresql-private-backup-rbac/  private PostgreSQL, Azure Backup, custom role
│   └── tests/
└── .gitignore                         state, .terraform/, tfvars, lock files
```

## Skills demonstrated

- Terraform/OpenTofu language: variable types and validation, `count`/`for_each`, `for` expressions, `dynamic` blocks, conditionals, splat, built-in functions, `lifecycle` and preconditions
- Reusable modules with small input/output interfaces
- Remote state in Azure Storage, one state key per stack, partial backend configuration, `terraform import`
- Secret handling: `random_password`, Key Vault with RBAC, sensitive outputs, no credentials in code
- Azure networking and compute: VNet, subnets, NSGs, NAT gateway, Linux VMs, management locks
- Web tier on VM Scale Sets: Application Gateway v2 with a WAF policy (OWASP rule set, Prevention mode), zone-balanced VMSS, cloud-init, Application Health extension, rolling upgrade policy, automatic instance repair, boot diagnostics
- Autoscale on CPU and memory with asymmetric scale-out/scale-in rules; Azure Monitor metric alerts, Action Groups, Log Analytics and diagnostic settings
- Private data services: PostgreSQL Flexible Server with VNet integration and private DNS, Entra ID authentication, backup retention and geo-redundant backup, server parameters; Key Vault behind a private endpoint
- Azure Backup: Recovery Services Vault, VM backup policy with daily/weekly/monthly/yearly retention
- Access control: custom RBAC role definitions with exact actions and assignable scopes, role assignments to Entra ID groups
- Containers on Azure: AKS with managed identity, ACR without admin user, `AcrPull` role assignment, hardened Kubernetes manifests
- Testing infrastructure code offline with `tofu test` and mocked providers
