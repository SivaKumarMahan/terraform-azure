# terraform-azure

Terraform and OpenTofu projects on Azure. Each folder is a small, separate project with its own state and its own README. They go from language basics (variables, meta-arguments, lifecycle, expressions, functions) to modules with remote state, and AKS with ACR.

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

"Static checks only" means `fmt`, `init -backend=false`, `validate` and, where there is a `tests/` folder, `tofu test` with mocked providers. Nothing was deployed to Azure in the review. See the "Tested" section of each README for the exact commands and results.

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install) 1.5+ or [OpenTofu](https://opentofu.org/docs/intro/install/) 1.6+
- [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli), logged in with `az login`
- An Azure subscription. Most projects expect an existing resource group `test-rg`
- For projects 3-7: a state storage account `tfstatestorage759` with a container `tfstate` in `test-rg` (project1 uses `tfstatestorage749`)
- For project2: `kubectl` and Docker

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
terraform test     # only in projects with a tests/ folder (project3)
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
└── .gitignore                         state, .terraform/, tfvars, lock files
```

## Skills demonstrated

- Terraform/OpenTofu language: variable types and validation, `count`/`for_each`, `for` expressions, `dynamic` blocks, conditionals, splat, built-in functions, `lifecycle` and preconditions
- Reusable modules with small input/output interfaces
- Remote state in Azure Storage, one state key per stack, partial backend configuration, `terraform import`
- Secret handling: `random_password`, Key Vault with RBAC, sensitive outputs, no credentials in code
- Azure networking and compute: VNet, subnets, NSGs, Linux VMs, management locks
- Containers on Azure: AKS with managed identity, ACR without admin user, `AcrPull` role assignment, hardened Kubernetes manifests
- Testing infrastructure code offline with `tofu test` and mocked providers
