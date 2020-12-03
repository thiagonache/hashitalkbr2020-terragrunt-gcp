# Terragrunt will copy the Terraform configurations specified by the source parameter, along with any files in the
# working directory, into a temporary folder, and execute your Terraform commands in that folder.
terraform {
  source = "git::git@github.com:terraform-google-modules/terraform-google-iam//modules/subnets_iam?ref=v5.1.0"
}

dependency "hostproject" {
  config_path = find_in_parent_folders("global/folder/projects/hostproject/deploy")
}

dependency "service_project" {
  config_path = find_in_parent_folders("projects/kubernetes/deploy")

  mock_outputs = {
    project_number                          = "12345678910"
    mock_outputs_allowed_terraform_commands = ["validate", "plan"]
  }
}

dependency "subnet" {
  config_path = find_in_parent_folders(format("global/folder/projects/hostproject/shared-vpc/%s/%s/subnets/gke-nodes", local.env_vars.environment, local.region_vars.region))
}

# Include all settings from the root terragrunt.hcl file
include {
  path = find_in_parent_folders()
}

locals {
  env_vars    = yamldecode(file(find_in_parent_folders("env_vars.yaml")))
  global_vars = yamldecode(file("${get_parent_terragrunt_dir()}/../vars/global.yaml"))
  region_vars = yamldecode(file(find_in_parent_folders("region_vars.yaml")))
  inputs_vars = yamldecode(file("inputs.yaml"))
  subnet_name = format("%s/%s-%s-%s-%s", local.region_vars.region, local.global_vars.prefix, local.env_vars.environment, local.region_vars.region, local.inputs_vars.service)
}

inputs = {
  bindings : {
    "roles/compute.networkUser" : [
      format("serviceAccount:%s@cloudservices.gserviceaccount.com", dependency.service_project.outputs.project_number),
      format("serviceAccount:service-%s@container-engine-robot.iam.gserviceaccount.com", dependency.service_project.outputs.project_number)
    ]
  }
  mode : "additive"
  subnets : [lookup(dependency.subnet.outputs.subnets, local.subnet_name).name]
  subnets_region : lookup(dependency.subnet.outputs.subnets, local.subnet_name).region
  project : dependency.hostproject.outputs.project_id

}
