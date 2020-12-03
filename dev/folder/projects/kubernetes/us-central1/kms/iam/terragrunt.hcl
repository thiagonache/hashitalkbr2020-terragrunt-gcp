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
  inputs_vars = yamldecode(file("inputs.yaml"))
}

terraform {
  source = format("%s?ref=%s", local.inputs_vars.source_module.url, local.inputs_vars.source_module.tag)
}

dependency "service_account" {
  config_path = find_in_parent_folders("kubernetes/service-account")
}

dependency "service_project" {
  config_path = find_in_parent_folders("projects/kubernetes/deploy")
}

inputs = {
  service_account_address = format("service-%s@container-engine-robot.iam.gserviceaccount.com", dependency.service_project.outputs.project_number)
  project_id              = dependency.service_project.outputs.project_id
  mode                    = local.inputs_vars.policy_mode
  project_roles           = local.inputs_vars.project_roles
}




