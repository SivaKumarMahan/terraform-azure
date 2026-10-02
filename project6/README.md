# Terraform expressions

1. Dynamic Expressions with Local Values
Create a local value block that defines NSG rules with the following properties:
One rule for SSH (port 22)
One rule for HTTP (port 80)
One rule for HTTPS (port 443)
Each rule should include:
Priority
Direction (Inbound)
Access (Allow)
Protocol (Tcp)
Source port ranges (*)
Destination port ranges (respective ports)
Source address prefix (*)
Destination address prefix (*)
Use these local values to create the Network Security Group rules for a VM
2. Conditional Expressions
Create a Network Security Group with a dynamic name based on environment
Requirements:
If var.environment is "dev", NSG name should be "nsg-dev-vm"
For any other environment value, NSG name should be "nsg-stage-vm"
Use a conditional expression to implement this logic
3. Splat Expression
Create outputs that:
Show all NSG rule names using splat expression