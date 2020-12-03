# Terragrunt will copy the Terraform configurations specified by the source parameter, along with any files in the
# working directory, into a temporary folder, and execute your Terraform commands in that folder.
terraform {
  source = format("%s?ref=%s", local.inputs_vars.source_module.url, local.inputs_vars.source_module.tag)
}

locals {
  inputs_vars = yamldecode(file("inputs.yaml"))
}

dependency "hostproject" {
  config_path = find_in_parent_folders("global/folder/projects/hostproject/deploy")
}

dependency "service_project" {
  config_path = find_in_parent_folders("projects/kubernetes/deploy")

  mock_outputs = {
    project_id                              = "my-kubernetes-project"
    project_number                          = "0123456789"
    mock_outputs_allowed_terraform_commands = ["validate", "plan"]
  }
}

# Include all settings from the root terragrunt.hcl file
include {
  path = find_in_parent_folders()
}

inputs = {
  host_project_id        = dependency.hostproject.outputs.project_id
  service_project_ids    = [dependency.service_project.outputs.project_id]
  service_project_number = dependency.service_project.outputs.project_number
}
