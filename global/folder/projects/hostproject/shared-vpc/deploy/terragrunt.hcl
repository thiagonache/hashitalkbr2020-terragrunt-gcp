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
  network_vars = yamldecode(file("${get_parent_terragrunt_dir()}/../vars/network.yaml"))
}

# Terragrunt will copy the Terraform configurations specified by the source parameter, along with any files in the
# working directory, into a temporary folder, and execute your Terraform commands in that folder.
terraform {
  source = format("%s?ref=%s", local.inputs_vars.source_module.url, local.inputs_vars.source_module.tag)
}

dependency "hostproject" {
  config_path = find_in_parent_folders("projects/hostproject/deploy")

  mock_outputs = {
    project_id                              = "host-project"
    mock_outputs_allowed_terraform_commands = ["validate", "plan"]
  }
}

inputs = {
  network_master_range = lookup(local.network_vars.iana_private_classes_cidrs, local.network_vars.k8s_rfc1918_networkclass)
  network_name         = local.inputs_vars.network_name
  project_id           = dependency.hostproject.outputs.project_id
  shared_vpc_host      = local.inputs_vars.shared_vpc_host
  subnets              = []
}

prevent_destroy = local.inputs_vars.prevent_destroy
