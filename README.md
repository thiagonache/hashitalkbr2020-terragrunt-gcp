# Hashitalk Brazil 2020

## Requirements

1. GCP Organization

   Follow the documentation [quickstart-organizations](https://cloud.google.com/resource-manager/docs/quickstart-organizations)

1. GCP Billing Account

   Follow the documentation [manage-billing-account](https://cloud.google.com/billing/docs/how-to/manage-billing-account)

1. GCP Folder

   Documentation at
   [creating-managing-folders](https://cloud.google.com/resource-manager/docs/creating-managing-folders)

   Eg.:

   `$ gcloud resource-manager folders create --organization=[REDACTED] --display-name=MY_FOLDER`

1. Two GCP projects

   We need two storage buckets on isolated projects. That said, create two new projects in a pre created folder. Documentation at [creating-managing-projects](https://cloud.google.com/resource-manager/docs/creating-managing-projects)

   Eg.:

   ```
   $ gcloud projects create hstlkbr2020-global-seed --organization [REDACTRED]
   $ gcloud beta billing projects link hstlkbr2020-global-seed --billing-account=[REDACTED]
   ```

   ```
   $ gcloud projects create hstlkbr2020-dev-seed --organization [REDACTRED]
   $ gcloud beta billing projects link hstlkbr2020-dev-seed --billing-account=[REDACTED]
   ```

## Variables

Set variables to be used on the shell commands

```
export TGCODE=~/dev/hashitalkbr2020-terragrunt-gcp
export ENV=dev
export ENV_PATH="${TGCODE}/${ENV}"
export REGION=us-east4
export PREFIX=hstlkbr
```

## Routine / Function

Terragrunt commands should be run in pairs of plan and apply in the same way as terraform.
This is complicated in the first deploy though because terragrunt needs dependency values. The solution is to mock these values in the terragrunt.hcl file.

To avoid a lot of duplication, refer to the two commands below when run terragrunt is mentioned.

```
$ terragrunt plan-all --terragrunt-[ignore or include]-external-dependencies 2>&1 | egrep -v '^\[terragrunt|Refreshing state...| => Module'
```

Review the plan carefully having in mind that some values are "mocked" and making sure that everything makes sense. After that, create all resources via apply.

```
$ terragrunt apply-all --terragrunt-[ignore or include]-external-dependencies
```

## Global YAML configs

Update network_vars.yaml, org_vars.yaml and project_vars.yaml in the code's root directory

Populate IPs in terragrunt.hcl on every subfolder at global/folder/projects/hostproject/ips

Update terragrunt.hcl on global directory

## How-to

1. Set terragrunt parallelism to avoid timeout on external resources.

   $ export TERRAGRUNT_PARALLELISM=4 # number of CPU cores

   Note: Parallelism limitation is only required if you are deploying an entire new environment from your desktop. In day to day work it is not required.

1. Run apply on the global folder in order to create the bucket.

   ```
   $ cd $TGCODE/global/folder/deploy
   $ terragrunt apply
   ```

   Note: There is a flow issue on terragrunt that requires a bucket to be created before you can run a terragrunt plan, but terragrunt only creates the bucket in the apply operation. So, before we can plan all we need to run an apply operation, the global folder is the best option because there's no dependencies and it's going to create a simple folder. Nothing will be broken if the hcl file is wrong.

1. Create everything under global

   ```
   $ cd ${TGCODE}/global
   ```

   Run terragrunt with ignore option

1. Clone the env directory

   ```
   $ cp -r ${TGCODE}/env_template ${ENV_PATH}
   ```

   On this example dev is the current template.

1. Update the following variables in ${ENV_PATH}/env_vars.yaml.

   - enabled_audit_policy
   - kubernetes_proxy

1. Update the following variables in ${ENV_PATH}/terragrunt.hcl

   - remote_state.config.bucket
   - remote_state.config.project

1. Update the following variables in ${ENV_PATH}/folder/projects/kubernetes/${REGION}/region_vars.yaml

   - location

1. Update variables in ${ENV_PATH}/folder/projects/kubernetes/${REGION}/gke/inputs.yaml

   - node_pools.[0]
   - node_pools.[1]

1. Create folder in order to create terraform bucket state files.

   ```
   $ cd ${ENV_PATH}/folder
   $ terragrunt apply
   ```

1. Create everything up to the dns

   ```
   $ cd ${ENV_PATH}/folder/projects/dns/clouddns/domains/ingress
   Run terragrunt with include option
   ```

1. Do/ask for domain delegation

1. Create everything up to the region itself
   ```
   $ cd ${ENV_PATH}/resources/${REGION}
   Run terragrunt with include option
   ```
