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
  inputs_vars  = yamldecode(file("inputs.yaml"))
  project_vars = yamldecode(file("${get_parent_terragrunt_dir()}/../vars/projects.yaml"))
}

terraform {
  source = format("%s?ref=%s", local.inputs_vars.source_module.url, local.inputs_vars.source_module.tag)
}

dependency "hostproject" {
  config_path = "../../deploy"

  mock_outputs = {
    project_id                              = "12345678910"
    mock_outputs_allowed_terraform_commands = ["validate", "plan"]
  }
}

inputs = {
  constraint = local.inputs_vars.constraint
  enforce    = local.inputs_vars.enforce
  policy_for = "project"
  project_id = dependency.hostproject.outputs.project_id
}

skip = local.project_vars.orgpolicies_skip_execution
