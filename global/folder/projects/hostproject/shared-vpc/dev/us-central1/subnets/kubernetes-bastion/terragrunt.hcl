# Terragrunt will copy the Terraform configurations specified by the source parameter, along with any files in the
# working directory, into a temporary folder, and execute your Terraform commands in that folder.
terraform {
  source = format("%s?ref=%s", local.inputs_vars.source_module.url, local.inputs_vars.source_module.tag)
}

locals {
  env_vars      = yamldecode(file(find_in_parent_folders("env_vars.yaml")))
  global_vars   = yamldecode(file("${get_parent_terragrunt_dir()}/../vars/global.yaml"))
  inputs_vars   = yamldecode(file("inputs.yaml"))
  region_vars   = yamldecode(file(find_in_parent_folders("region_vars.yaml")))
  subnet_k8spod = format("%s-%s-%s-pod", local.global_vars.prefix, local.env_vars.environment, local.region_vars.region)
  subnet_k8ssvc = format("%s-%s-%s-svc", local.global_vars.prefix, local.env_vars.environment, local.region_vars.region)
  subnet_name   = format("%s-%s-%s-%s", local.global_vars.prefix, local.env_vars.environment, local.region_vars.region, local.inputs_vars.subnet_name)
}

dependency "hostproject" {
  config_path = find_in_parent_folders("projects/hostproject/deploy")
}

dependency "shared_vpc" {
  config_path = find_in_parent_folders("hostproject/shared-vpc/deploy")
}

dependency "kubernetes_bastion" {
  config_path = find_in_parent_folders("hostproject/ips/kubernetes-bastion")
}

# Include all settings from the root terragrunt.hcl file
include {
  path = find_in_parent_folders()
}

inputs = {
  project_id   = dependency.hostproject.outputs.project_id
  network_name = dependency.shared_vpc.outputs.network_name
  subnets = [
    {
      subnet_name   = local.subnet_name
      subnet_ip     = lookup(dependency.kubernetes_bastion.outputs.network_cidr_blocks, local.subnet_name)
      subnet_region = local.region_vars.region
    }
  ]
}
