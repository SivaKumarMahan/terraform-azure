# Terraform Functions Learning Guide - Assignments


## Console Commands

Practice these fundamental commands in `terraform console` before starting the assignments:

```hcl
# Basic String Manipulation
lower("HELLO WORLD")
max(5, 12, 9)
trim("  hello  ")
chomp("hello\n")
reverse(["a", "b", "c"])
```

## Assignments

### Assignment 1: Project Naming Convention

**Functions Focus**: `lower`, `replace`

**Scenario**:  
Your company requires all resource names to be lowercase and replace spaces with hyphens.

**Input**:
```
"Project ALPHA Resource"
```

**Required Output**:
```
"project-alpha-resource"
```

**Tasks**:
1. Create a variable `project_name` with the given input
2. Create a local that uses the required functions
3. Use the transformed name to create an Azure resource group
4. Add an output to display the transformed name

---

### Assignment 2: Resource Tagging

**Function Focus**: `merge`

**Scenario**:  
You need to combine default company tags with environment-specific tags.

**Input**:
```hcl
# Default tags
{
    company    = "TechCorp"
    managed_by = "terraform"
}

# Environment tags
{
    environment  = "production"
    cost_center = "cc-123"
}
```

**Tasks**:
1. Create locals for both tag sets
2. Merge them using the appropriate function
3. Apply them to a resource group
4. Create an output to display the combined tags

---

### Assignment 3: Storage Account Naming

**Function Focus**: `substr`

**Scenario**:  
Azure storage account names must be less than 24 characters and use only lowercase letters and numbers.

**Input**:
```
"projectalphastorageaccount"
```

**Requirements**:
- Maximum length: 23 characters
- All lowercase
- No special characters

**Tasks**:
1. Create a function to process the storage account name
2. Ensure it meets Azure requirements
3. Apply it to a storage account resource
4. Add validation to prevent invalid names

---

### Assignment 4: Network Security Group Rules

**Functions Focus**: `split`, `join`

**Scenario**:  
Transform a comma-separated list of ports into a specific format for documentation.

**Input**:
```
"80,443,8080,3306"
```

**Required Output**:
```
"port-80-port-443-port-8080-port-3306"
```

**Tasks**:
1. Create a variable for the port list
2. Transform it using appropriate functions
3. Create an output with the formatted result
4. Add validation for port numbers

---

### Assignment 5: Resource Lookup

**Function Focus**: `lookup`

**Scenario**:  
Implement environment configuration mapping with fallback values.

**Input**:
```hcl
environments = {
    dev = {
        instance_size = "small"
        redundancy    = "low"
    }
    prod = {
        instance_size = "large"
        redundancy    = "high"
    }
}
```

**Tasks**:
1. Create the environments map
2. Implement lookup with fallback
3. Create outputs for the configuration
4. Handle invalid environment names

---

### Assignment 6: VM Size Validation

**Functions Focus**: `length`, `contains`

**Scenario**:  
Implement validation rules for VM sizes.

**Requirements**:
- Length between 2 and 20 characters
- Must contain 'standard'

**Test Cases**:
```hcl
Valid:    "standard_D2s_v3"
Invalid:  "basic_A0"
Invalid:  "standard_D2s_v3_extra_long_name"
```

**Tasks**:
1. Create a variable for VM size
2. Implement both validation rules
3. Test with various inputs
4. Create helpful error messages

---

### Assignment 7: Backup Configuration

**Functions Focus**: `endswith`, `sensitive`

**Scenario**:  
Create a secure backup configuration handler.

**Input**:
```hcl
backup_name = "daily_backup"
credential  = "xyz123" # Should be sensitive
```

**Requirements**:
- Name must end with '_backup'
- Credentials must be marked sensitive
- Handle validation failures

**Tasks**:
1. Create variables for both inputs
2. Implement proper validation
3. Handle sensitive data correctly
4. Create secure outputs

---

### Assignment 8: File Path Processing

**Functions Focus**: `fileexists`, `dirname`

**Scenario**:  
Validate Terraform configuration file paths.

**Paths to Validate**:
```
./configs/main.tf
./configs/variables.tf
```

**Tasks**:
1. Create path validation function
2. Extract directory names
3. Handle missing files
4. Create status outputs

---

### Assignment 9: Resource Set Management

**Functions Focus**: `toset`, `concat`

**Scenario**:  
Manage unique resource locations.

**Input**:
```hcl
user_locations    = ["eastus", "westus", "eastus"]
default_locations = ["centralus"]
```

**Tasks**:
1. Combine location lists
2. Remove duplicates
3. Create location validation
4. Output unique locations

---

### Assignment 10: Cost Calculation

**Functions Focus**: `abs`, `max`

**Scenario**:  
Process monthly infrastructure costs.

**Input**:
```hcl
monthly_costs = [-50, 100, 75, 200]
```

**Required**:
- Convert negative values to positive
- Find maximum cost
- Calculate averages

**Tasks**:
1. Create cost processing function
2. Handle negative values
3. Calculate statistics
4. Create cost report output

---

### Assignment 11: Timestamp Management

**Functions Focus**: `timestamp`, `formatdate`

**Scenario**:  
Generate formatted timestamps for different purposes.

**Required Formats**:
```
Resource Names: YYYYMMDD
Tags: DD-MM-YYYY
```

**Tasks**:
1. Create timestamp generation
2. Format for different uses
3. Implement validation
4. Create formatted outputs

---

### Assignment 12: File Content Handling

**Functions Focus**: `file`, `sensitive`

**Scenario**:  
Securely handle configuration file content.

**Requirements**:
- Read from config.json
- Mark content as sensitive
- Handle file errors
- Validate JSON structure

**Tasks**:
1. Implement secure file reading
2. Add error handling
3. Validate file content
4. Create secure outputs

## Outputs
Outputs:

assignment1_formatted_name = "project7-terraform"
assignment2_tags = tomap({
  "company" = "dummy"
  "cost-center" = "it"
  "environment" = "dev"
  "managed_by" = "terraform"
})
assignment3_storage_name = "tfstatestorage757"
assignment4_ports_doc = "port-22-port-80-port-443"
assignment4_ports_validation = true
assignment5_env_config = {
  "instance_size" = "low"
  "redundancy" = "small"
}
assignment6_vm_size = "Standard_D2s_v3"
backup_configuration = <sensitive>
cost_report = {
  "avg_cost" = 106.25
  "max_cost" = 200
  "positive_costs" = [
    50,
    100,
    75,
    200,
  ]
}
file_validation_status = {
  "./configs/main.tf" = {
    "dirname" = "configs"
    "exists" = false
  }
  "./configs/variables.tf" = {
    "dirname" = "configs"
    "exists" = false
  }
}
nsg_name = "nsg-dev-vm"
nsg_rule_names = [
  "allow_port_22",
  "allow_port_443",
  "allow_port_80",
]