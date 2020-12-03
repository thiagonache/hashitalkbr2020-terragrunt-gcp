# Terragrunt will copy the Terraform configurations specified by the source parameter, along with any files in the
# working directory, into a temporary folder, and execute your Terraform commands in that folder.
terraform {
  source = format("%s?ref=%s", local.inputs_vars.source_module.url, local.inputs_vars.source_module.tag)
}

locals {
  env_vars              = yamldecode(file(find_in_parent_folders("env_vars.yaml")))
  network_vars          = yamldecode(file(find_in_parent_folders("vars/network.yaml")))
  global_vars           = yamldecode(file(find_in_parent_folders("vars/global.yaml")))
  projects_vars         = yamldecode(file(find_in_parent_folders("vars/projects.yaml")))
  region_vars           = yamldecode(file(find_in_parent_folders("region_vars.yaml")))
  inputs_vars           = yamldecode(file("inputs.yaml"))
  node_subnet_name      = format("%s/%s-%s-%s-%s", local.region_vars.region, local.global_vars.prefix, local.env_vars.environment, local.region_vars.region, local.inputs_vars.service_name)
  bastion_subnet_name   = format("%s/%s-%s-%s-%s", local.region_vars.region, local.global_vars.prefix, local.env_vars.environment, local.region_vars.region, "bastion")
  k8smaster_subnet_name = format("%s-%s-%s-%s", local.global_vars.prefix, local.env_vars.environment, local.region_vars.region, format("%s-%s", "kubernetes", "master"))
}

dependency "iam_hostproject" {
  config_path = find_in_parent_folders("iam/hostproject")

  mock_outputs = {
    placeholder                             = "placeholder"
    mock_outputs_allowed_terraform_commands = ["validate", "plan"]
  }
}

dependency "iam_serviceproject" {
  config_path = find_in_parent_folders("iam/serviceproject")

  mock_outputs = {
    placeholder                             = "placeholder"
    mock_outputs_allowed_terraform_commands = ["validate", "plan"]
  }
}

dependency "iam_subnet" {
  config_path = "../iam"

  mock_outputs = {
    placeholder                             = "placeholder"
    mock_outputs_allowed_terraform_commands = ["validate", "plan"]
  }
}

dependency "hostproject" {
  config_path = find_in_parent_folders("global/folder/projects/hostproject/deploy")
}

dependency "service_account" {
  config_path = find_in_parent_folders("kubernetes/service-account")

  mock_outputs = {
    email                                   = "my-service-account@my-project.iam.gserviceaccount.com"
    mock_outputs_allowed_terraform_commands = ["validate", "plan"]
  }
}

dependency "kubernetes_project" {
  config_path = find_in_parent_folders("projects/kubernetes/deploy")

  mock_outputs = {
    project_id                              = "my-kubernetes-project"
    mock_outputs_allowed_terraform_commands = ["validate", "plan"]
  }
}

dependency "shared_vpc" {
  config_path = find_in_parent_folders("global/folder/projects/hostproject/shared-vpc/deploy")
}

dependency "subnet" {
  config_path = find_in_parent_folders(format("global/folder/projects/hostproject/shared-vpc/%s/%s/subnets/gke-nodes", local.env_vars.environment, local.region_vars.region))
}

dependency "bastion_subnet" {
  config_path = find_in_parent_folders(format("global/folder/projects/hostproject/shared-vpc/%s/%s/subnets/kubernetes-bastion", local.env_vars.environment, local.region_vars.region))
}

dependency "k8smaster_ips" {
  config_path = find_in_parent_folders("global/folder/projects/hostproject/ips/kubernetes-master")
}

dependency "kms_iam" {
  config_path = "../../kms/iam"
}

dependency "kms_key" {
  config_path = "../../kms/deploy"
}

# Include all settings from the root terragrunt.hcl file
include {
  path = find_in_parent_folders()
}

inputs = {
  # note that values hard coded are non negotiable on my architectural decision.
  # Meaning that they should not be changed at all on that specific case.
  create_service_account        = false
  database_encryption           = [{ state = "ENCRYPTED", key_name = values(dependency.kms_key.outputs.keys)[0] }]
  deploy_using_private_endpoint = true
  enable_binary_authorization   = false
  enable_pod_security_policy    = true
  enable_private_endpoint       = true
  enable_private_nodes          = true
  enable_shielded_nodes         = true
  horizontal_pod_autoscaling    = true
  host_project_id               = dependency.hostproject.outputs.project_id
  http_load_balancing           = false
  kubernetes_version            = local.inputs_vars.kubernetes_version
  master_authorized_networks = [
    { cidr_block = lookup(dependency.bastion_subnet.outputs.subnets, local.bastion_subnet_name).ip_cidr_range, display_name = "bastion-subnet" }
  ]
  master_ipv4_cidr_block   = lookup(dependency.k8smaster_ips.outputs.network_cidr_blocks, local.k8smaster_subnet_name)
  name                     = format("%s-%s", dependency.kubernetes_project.outputs.project_name, local.region_vars.region)
  network                  = dependency.shared_vpc.outputs.network_name
  network_project_id       = dependency.hostproject.outputs.project_id
  node_pools               = local.inputs_vars.node_pools
  node_pools_oauth_scopes  = local.inputs_vars.node_pools_oauth_scopes
  node_pools_labels        = local.inputs_vars.node_pools_labels
  node_pools_metadata      = local.inputs_vars.node_pools_metadata
  node_pools_tags          = local.inputs_vars.node_pools_tags
  region                   = local.region_vars.region
  release_channel          = local.inputs_vars.release_channel
  remove_default_node_pool = true
  ip_range_pods            = lookup(dependency.subnet.outputs.subnets, local.node_subnet_name).secondary_ip_range[0].range_name
  ip_range_services        = lookup(dependency.subnet.outputs.subnets, local.node_subnet_name).secondary_ip_range[1].range_name
  service_account          = dependency.service_account.outputs.email
  subnetwork               = lookup(dependency.subnet.outputs.subnets, local.node_subnet_name).name
  project_id               = dependency.kubernetes_project.outputs.project_id
}
