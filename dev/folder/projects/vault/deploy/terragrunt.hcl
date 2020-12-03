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
  env_vars     = yamldecode(file(find_in_parent_folders("env_vars.yaml")))
  inputs_vars  = yamldecode(file("inputs.yaml"))
  global_vars  = yamldecode(file("${get_parent_terragrunt_dir()}/../vars/global.yaml"))
  project_vars = yamldecode(file("${get_parent_terragrunt_dir()}/../vars/projects.yaml"))
}

terraform {
  source = format("%s?ref=%s", local.inputs_vars.source_module.url, local.inputs_vars.source_module.tag)
}

dependency "sub_folders" {
  config_path = find_in_parent_folders(format("%s/folder/deploy", local.env_vars.environment))

  mock_outputs = {
    id                                      = "my-folder"
    mock_outputs_allowed_terraform_commands = ["validate", "plan"]
  }
}

inputs = {
  activate_apis = distinct(concat(local.project_vars.activate_apis, local.inputs_vars.activate_extra_apis))
  folder_id     = dependency.sub_folders.outputs.id
  labels        = merge(local.global_vars.labels, local.inputs_vars.labels)
  project_id    = format("%s-%s-%s", local.global_vars.prefix, local.env_vars.environment, local.inputs_vars.name)
  name          = format("%s-%s-%s", local.global_vars.prefix, local.env_vars.environment, local.inputs_vars.name)
}
