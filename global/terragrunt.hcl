# terragrunt root hcl
remote_state {
  backend = "gcs"
  config = {
    bucket                 = format("%s-%s-tf-state", "hstlkbr2020", "global")
    prefix                 = path_relative_to_include()
    location               = "US"
    project                = "hstlkbr2020-global-seed"
    skip_bucket_creation   = false
    skip_bucket_versioning = false
  }
}

inputs = merge(
  yamldecode(file("${get_parent_terragrunt_dir()}/../vars/global.yaml")),
  yamldecode(file("${get_parent_terragrunt_dir()}/../vars/projects.yaml"))
)

terraform_version_constraint  = "= 0.13.5"
terragrunt_version_constraint = "= 0.23.31"

