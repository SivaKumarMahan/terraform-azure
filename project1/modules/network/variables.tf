variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "vnet_name" {
  type = string
}

variable "subnet_name" {
  type = string
}

variable "allowed_ssh_cidr" {
  description = "Source CIDR allowed to reach port 22."
  type        = string
}
