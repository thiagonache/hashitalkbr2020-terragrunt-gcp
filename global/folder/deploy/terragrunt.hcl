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
  env_vars    = yamldecode(file(find_in_parent_folders("env_vars.yaml")))
  global_vars = yamldecode(file("${get_parent_terragrunt_dir()}/../vars/global.yaml"))
  inputs_vars = yamldecode(file("inputs.yaml"))
}

terraform {
  source = format("%s?ref=%s", local.inputs_vars.source_module.url, local.inputs_vars.source_module.tag)
}

inputs = {
  all_folder_admins = lookup(local.global_vars.admins, "all")
  names             = list(local.env_vars.environment)
  per_folder_admins = lookup(local.global_vars.admins, local.env_vars.environment)
  set_roles         = local.inputs_vars.set_roles
}
