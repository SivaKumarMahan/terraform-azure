variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "vm_name" {
  type = string
}

variable "ssh_public_key" {
  description = "SSH public key content (not a file path)."
  type        = string
}
