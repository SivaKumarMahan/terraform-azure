locals {
  # project name normalized (lowercase & spaces->hyphen)
  formatted_name = lower(replace(var.project_name, " ", "-"))

  # merge tags
  merged_tags = merge(var.default_tags, var.environment_tags)

  # storage account normalization
  # - lowercase
  # - remove any non [a-z0-9] characters
  # - enforce max length 23 (Azure allows up to 24; using 23 to be safe)
  # lower() runs first, otherwise the regex would drop every upper-case letter
  storage_normalized = substr(replace(lower(var.storage_account_name), "/[^a-z0-9]/", ""), 0, 23)

  # ports - split & join to "port-80-port-443-..."
  ports_list_clean = [for port in split(",", var.allowed_ports_str) : trim(port, " \t\n\r")]
  ports_prefixed   = [for port in local.ports_list_clean : "port-${port}"]
  ports_joined     = join("-", local.ports_prefixed)

  # validate ports are numeric and in range 1-65535
  ports_valid = alltrue([for p in local.ports_list_clean : can(regex("^\\d+$", p)) && tonumber(p) >= 1 && tonumber(p) <= 65535])

  # environment lookup with fallback
  env_config = lookup(var.envs, var.environment, var.envs["dev"])

  # vm_size already validated in variable block; expose locally
  vm_size_local = var.vm_size

  # Securely store backup credential
  secure_credential = sensitive(var.credential)

  # File Path Processing
  # Functions: fileexists(), dirname()
  file_paths = [
    "./configs/main.tf",
    "./configs/variables.tf"
  ]

  file_status = {
    for path in local.file_paths : path => {
      exists  = fileexists(path)
      dirname = dirname(path)
    }
  }

  # Assignment 9: combine lists and remove duplicates
  unique_locations = toset(concat(var.user_locations, var.default_locations))

  positive_costs = [for cost in var.monthly_costs : abs(cost)]
  max_cost       = max(local.positive_costs...)
  avg_cost       = sum(local.positive_costs) / length(local.positive_costs)

  current_time = timestamp()
  name_date    = formatdate("YYYYMMDD", local.current_time)
  tag_date     = formatdate("DD-MM-YYYY", local.current_time)

}