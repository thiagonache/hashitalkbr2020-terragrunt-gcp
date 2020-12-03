# Terragrunt will copy the Terraform configurations specified by the source parameter, along with any files in the
# working directory, into a temporary folder, and execute your Terraform commands in that folder.

# Blocks processing order:
# 1. include
# 2. locals
# 3. terraform
# 4. dependencies
# 5. each dependency
# 6. everything else. ie inputs
# 7. The configuration referenced by include block

# Include all settings from the root terragrunt.hcl file
include {
  path = find_in_parent_folders()
}

locals {
  inputs_vars          = yamldecode(file("inputs.yaml"))
  network_vars         = yamldecode(file("${get_parent_terragrunt_dir()}/../vars/network.yaml"))
  network_master_range = lookup(local.network_vars.iana_private_classes_cidrs, local.network_vars.k8s_rfc1918_networkclass)
  k8s_master_range     = cidrsubnet(local.network_master_range, local.network_vars.k8s_internal_newbits, local.network_vars.k8s_internal_indexes["master"])
}

terraform {
  source = format("%s?ref=%s", local.inputs_vars.source_module.url, local.inputs_vars.source_module.tag)
}

inputs = {
  base_cidr_block = local.k8s_master_range
  networks        = local.inputs_vars.networks
}
