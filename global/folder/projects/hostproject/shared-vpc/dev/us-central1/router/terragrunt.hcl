# Terragrunt will copy the Terraform configurations specified by the source parameter, along with any files in the
# working directory, into a temporary folder, and execute your Terraform commands in that folder.
terraform {
  source = "git::git@github.com:terraform-google-modules/terraform-google-cloud-router?ref=v0.3.0"
}

locals {
  region_vars = yamldecode(file(find_in_parent_folders("region_vars.yaml")))
  global_vars = yamldecode(file("${get_parent_terragrunt_dir()}/../vars/global.yaml"))
  env_vars    = yamldecode(file(find_in_parent_folders("env_vars.yaml")))
}

dependency "hostproject" {
  config_path = find_in_parent_folders("projects/hostproject/deploy")
}

dependency "shared_vpc" {
  config_path = find_in_parent_folders("projects/hostproject/shared-vpc/deploy")
}

# Include all settings from the root terragrunt.hcl file
include {
  path = find_in_parent_folders()
}

inputs = {
  name    = format("%s-%s-%s-router-%s", local.global_vars.prefix, local.region_vars.region, dependency.shared_vpc.outputs.network_name, local.env_vars.environment)
  project = dependency.hostproject.outputs.project_id
  region  = local.region_vars.region
  network = dependency.shared_vpc.outputs.network_name
}
