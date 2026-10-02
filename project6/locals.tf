locals {
  nsg_rules = {
    allow_ssh = {
      priority               = 100
      destination_port_range = 22
      description            = "Allow SSH"
    }
    allow_http = {
      priority               = 110
      destination_port_range = 80
      description            = "Allow HTTP"
    }
    allow_https = {
      priority               = 120
      destination_port_range = 443
      description            = "Allow HTTPS"
    }
  }
}