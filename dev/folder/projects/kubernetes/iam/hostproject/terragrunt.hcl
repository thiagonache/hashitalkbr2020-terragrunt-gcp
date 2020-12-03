# Terragrunt will copy the Terraform configurations specified by the source parameter, along with any files in the
# working directory, into a temporary folder, and execute your Terraform commands in that folder.
terraform {
  source = format("%s?ref=%s", local.inputs_vars.source_module.url, local.inputs_vars.source_module.tag)
}

dependency "service_project" {
  config_path = find_in_parent_folders("projects/kubernetes/deploy")

  mock_outputs = {
    project_number                          = "0123456789"
    mock_outputs_allowed_terraform_commands = ["validate", "plan"]
  }
}

dependency "hostproject" {
  config_path = find_in_parent_folders("global/folder/projects/hostproject/deploy")
}

# Include all settings from the root terragrunt.hcl file
include {
  path = find_in_parent_folders()
}

locals {
  env_vars    = yamldecode(file(find_in_parent_folders("env_vars.yaml")))
  inputs_vars = yamldecode(file("inputs.yaml"))
}

inputs = {
  bindings = {
    "roles/container.hostServiceAgentUser" = [format("serviceAccount:service-%s@container-engine-robot.iam.gserviceaccount.com", dependency.service_project.outputs.project_number)]
  }
  mode     = local.inputs_vars.policy_mode
  projects = [dependency.hostproject.outputs.project_id]

}
