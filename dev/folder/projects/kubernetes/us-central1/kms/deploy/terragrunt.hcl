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
  region_vars = yamldecode(file(find_in_parent_folders("region_vars.yaml")))
}

terraform {
  source = format("%s?ref=%s", local.inputs_vars.source_module.url, local.inputs_vars.source_module.tag)
}

dependency "service_project" {
  config_path = find_in_parent_folders("projects/kubernetes/deploy")
}

inputs = {
  location : local.region_vars.region
  keyring : format("%s-%s-%s-k8s-secrets-keyring", local.global_vars.prefix, local.env_vars.environment, local.region_vars.region)
  keys : [format("%s-%s-%s-k8s-secrets-keyy", local.global_vars.prefix, local.env_vars.environment, local.region_vars.region)]
  set_owners_for : [format("%s-%s-%s-k8s-secrets-keyy", local.global_vars.prefix, local.env_vars.environment, local.region_vars.region)]
  owners : local.global_vars.security_owners
  prevent_destroy : local.inputs_vars.prevent_destroy
  project_id : dependency.service_project.outputs.project_id
}




