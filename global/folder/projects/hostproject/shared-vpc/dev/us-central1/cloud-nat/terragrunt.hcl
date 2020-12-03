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
  inputs_vars = yamldecode(file("inputs.yaml"))
  env_vars    = yamldecode(file(find_in_parent_folders("env_vars.yaml")))
  global_vars = yamldecode(file("${get_parent_terragrunt_dir()}/../vars/global.yaml"))
  region_vars = yamldecode(file(find_in_parent_folders("region_vars.yaml")))
}

terraform {
  source = format("%s?ref=%s", local.inputs_vars.source_module.url, local.inputs_vars.source_module.tag)
}

dependency "hostproject" {
  config_path = find_in_parent_folders("projects/hostproject/deploy")
}

dependency "bastion_subnet" {
  config_path = "../subnets/kubernetes-bastion"
}

dependency "kubernetes_subnet" {
  config_path = "../subnets/gke-nodes"

  mock_outputs = {
    subnets                                 = { "kubernetes-subnet" = "fake" }
    mock_outputs_allowed_terraform_commands = ["validate", "plan"]
  }
}

dependency "router" {
  config_path = find_in_parent_folders("router")

  mock_outputs = {
    router                                  = { "name" = "my-router" }
    mock_outputs_allowed_terraform_commands = ["validate", "plan"]
  }
}

inputs = {
  # note: values hard coded in below are by design. changing it requires
  # changing how the network works in terms of isolation
  name                               = format("%s-%s-nat-%s", local.global_vars.prefix, local.region_vars.region, local.env_vars.environment)
  project_id                         = dependency.hostproject.outputs.project_id
  region                             = local.region_vars.region
  router                             = dependency.router.outputs.router.name
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS" # isolate environment traffic in the same region by env
  subnetworks = [
    {
      name                     = keys(dependency.bastion_subnet.outputs.subnets)[0]
      source_ip_ranges_to_nat  = ["ALL_IP_RANGES"]
      secondary_ip_range_names = []
    },
    {
      name                     = keys(dependency.kubernetes_subnet.outputs.subnets)[0]
      source_ip_ranges_to_nat  = ["ALL_IP_RANGES"]
      secondary_ip_range_names = []
    }
  ]
}

