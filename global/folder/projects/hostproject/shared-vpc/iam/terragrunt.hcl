# Terragrunt will copy the Terraform configurations specified by the source parameter, along with any files in the
# working directory, into a temporary folder, and execute your Terraform commands in that folder.
terraform {
  source = format("%s?ref=%s", local.inputs_vars.source_module.url, local.inputs_vars.source_module.tag)
}

# Include all settings from the root terragrunt.hcl file
include {
  path = find_in_parent_folders()
}

dependency "hostproject" {
  config_path = find_in_parent_folders("projects/hostproject/deploy")

  mock_outputs = {
    project_id                              = "host-project"
    mock_outputs_allowed_terraform_commands = ["validate", "plan"]
  }
}

locals {
  inputs_vars  = yamldecode(file("inputs.yaml"))
  network_vars = yamldecode(file("${get_parent_terragrunt_dir()}/../vars/network.yaml"))
}

inputs = {
  projects : [dependency.hostproject.outputs.project_id]
  mode : local.inputs_vars.policy_mode
  bindings : {
    format("roles/%s", local.inputs_vars.role) : local.network_vars.network_iam_members
  }
}
