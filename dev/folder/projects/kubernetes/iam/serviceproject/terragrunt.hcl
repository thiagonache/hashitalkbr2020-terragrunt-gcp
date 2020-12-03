# Terragrunt will copy the Terraform configurations specified by the source parameter, along with any files in the
# working directory, into a temporary folder, and execute your Terraform commands in that folder.
terraform {
  source = format("%s?ref=%s", local.inputs_vars.source_module.url, local.inputs_vars.source_module.tag)
}

dependency "service_account" {
  config_path = find_in_parent_folders("kubernetes/service-account")

  mock_outputs = {
    email                                   = "my-service-account@my-project.iam.gserviceaccount.com"
    mock_outputs_allowed_terraform_commands = ["validate", "plan"]
  }
}

dependency "service_project" {
  config_path = find_in_parent_folders("projects/kubernetes/deploy")

  mock_outputs = {
    project_id                              = "my-kubernetes-project"
    project_number                          = "0123456789"
    mock_outputs_allowed_terraform_commands = ["validate", "plan"]
  }
}

dependency "svpc_access" {
  config_path = find_in_parent_folders("kubernetes/svpc-access")

  mock_outputs = {
    placeholder                             = "placeholder"
    mock_outputs_allowed_terraform_commands = ["validate", "plan"]
  }
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
    "roles/compute.admin" = [format("serviceAccount:service-%s@container-engine-robot.iam.gserviceaccount.com", dependency.service_project.outputs.project_number)]
    "roles/monitoring.metricWriter" = [
      format("serviceAccount:service-%s@container-engine-robot.iam.gserviceaccount.com", dependency.service_project.outputs.project_number),
      format("serviceAccount:%s", dependency.service_account.outputs.email)
    ]
    "roles/logging.logWriter" = [format("serviceAccount:service-%s@container-engine-robot.iam.gserviceaccount.com", dependency.service_project.outputs.project_number)]
  }
  mode     = local.inputs_vars.policy_mode
  projects = [dependency.service_project.outputs.project_id]

}
