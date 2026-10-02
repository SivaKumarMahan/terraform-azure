# Terraform Resource meta arguments
count — simple, indexed iteration
count is used when you want multiple copies of the same resource, based on a number.
count expects a number (count = 2 or count = length(list)).
count.index is the zero-based index (0, 1, 2...).
Best suited for lists (e.g., ["sa1", "sa2", "sa3"]).

for_each — flexible, key-value iteration
for_each allows you to iterate over maps or sets, and gives each resource a unique key.
for_each can iterate over a map or set of strings.
Each instance is uniquely identified by each.key (if map) or each.value (if set).
Terraform creates separate resources with stable keys.

for expression — used in outputs or variables
for is not for creating multiple resources, but for transforming data (like list comprehensions in Python).

Outputs:

names_of_storage_accounts = [
  "devstgoiuacct1",
  "devstgoiuacct2",
  "devstgoiuacct3",
]