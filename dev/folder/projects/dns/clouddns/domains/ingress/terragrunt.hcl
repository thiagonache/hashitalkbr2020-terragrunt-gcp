# Terragrunt will copy the Terraform configurations specified by the source parameter, along with any files in the
# working directory, into a temporary folder, and execute your Terraform commands in that folder.
terraform {
  source = format("%s?ref=%s", local.inputs_vars.source_module.url, local.inputs_vars.source_module.tag)
}

dependency "dns_project" {
  config_path = find_in_parent_folders(format("%s/folder/projects/dns/deploy", local.env_vars.environment))

  mock_outputs = {
    project_id                              = "dns-project"
    mock_outputs_allowed_terraform_commands = ["validate", "plan"]
  }
}

# Include all settings from the root terragrunt.hcl file
include {
  path = find_in_parent_folders()
}

locals {
  domain_name  = replace(local.network_vars.domain_name, ".", "-") # variable for resource naming (dots are not allowed)
  env_vars     = yamldecode(file(find_in_parent_folders("env_vars.yaml")))
  global_vars  = yamldecode(file("${get_parent_terragrunt_dir()}/../vars/global.yaml"))
  inputs_vars  = yamldecode(file("inputs.yaml"))
  network_vars = yamldecode(file("${get_parent_terragrunt_dir()}/../vars/network.yaml"))
  sub_domain   = replace(local.network_vars.sub_domain, ".", "-") # variable for resource naming (dots are not allowed)
}

inputs = {
  project_id = dependency.dns_project.outputs.project_id
  type       = local.network_vars.dns_type
  name       = format("%s-%s-%s-%s", local.global_vars.prefix, local.sub_domain, local.env_vars.environment, local.domain_name)
  domain     = format("%s.%s.%s.", local.network_vars.sub_domain, local.env_vars.environment, local.network_vars.domain_name)
}

prevent_destroy = local.inputs_vars.prevent_destroy
