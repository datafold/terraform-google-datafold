=======
# Datafold Google module

This repository provisions infrastructure resources on Google Cloud for deploying Datafold using the datafold-operator.

## About this module

**⚠️ Important**: This module is now **optional**. If you already have GKE infrastructure in place, you can configure the required resources independently. This module is primarily intended for customers who need to set up the complete infrastructure stack for GKE deployment.

The module provisions Google Cloud infrastructure resources that are required for Datafold deployment. Application configuration is now managed through the `datafoldapplication` custom resource on the cluster using the datafold-operator, rather than through Terraform application directories.

## Breaking Changes

### Load Balancer Deployment (Default Changed)

**Breaking Change**: The load balancer is **no longer deployed by default**. The default behavior has been toggled to `deploy_lb = false`.

- **Previous behavior**: Load balancer was deployed by default
- **New behavior**: Load balancer deployment is disabled by default
- **Action required**: If you need a load balancer, you must explicitly set `deploy_lb = true` in your configuration, so that you don't lose it. (in the case it does happen, you need to redeploy it and then update your DNS to the new LB IP).

### Application Directory Removal

- The "application" directory is no longer part of this repository
- Application configuration is now managed through the `datafoldapplication` custom resource on the cluster

## Prerequisites

* A Google Cloud account, preferably a new isolated one.
* Terraform >= 1.4.6
* A customer contract with Datafold
  * The application does not work without credentials supplied by sales
* Access to our public helm-charts repository

The full deployment will create the following resources:

* Google VPC
* Google subnets
* Google GCS bucket for clickhouse backups
* Google Cloud Load Balancer (optional, disabled by default)
* Google-managed SSL certificate (if load balancer is enabled)
* Three persistent disk volumes for local data storage
* Cloud SQL PostgreSQL database
* A GKE cluster
* Service accounts for the GKE cluster to perform actions outside of its cluster boundary:
  * Provisioning persistent disk volumes
  * Updating Network Endpoint Group to route traffic to pods directly
  * Managing GCS bucket access for ClickHouse backups

**Infrastructure Dependencies**: For a complete list of required infrastructure resources and detailed deployment guidance, see the [Datafold Dedicated Cloud GCP Deployment Documentation](https://docs.datafold.com/datafold-deployment/dedicated-cloud/gcp).

## Negative scope

* This module will not provision DNS names in your zone.

## How to use this module

* See the example for a potential setup, which has dependencies on our helm-charts

The example directory contains a single deployment example for infrastructure setup.

Setting up the infrastructure:

* It is easiest if you have full admin access in the target project.
* Pre-create a symmetric encryption key that is used to encrypt/decrypt secrets of this deployment.
  * Use the alias instead of the `mrk` link. Put that into `locals.tf`
* **Certificate Requirements** (depends on load balancer deployment method):
  * **If deploying load balancer from this Terraform module** (`deploy_lb = true`): Pre-create and validate the SSL certificate in your DNS, then refer to that certificate in main.tf using its domain name (Replace "datafold.example.com")
  * **If deploying load balancer from within Kubernetes**: The certificate will be created automatically, but you must wait for it to become available and then validate it in your DNS after the deployment is complete
* Change the settings in locals.tf
  * provider_region = which region you want to deploy in.
  * project_id = The GCP project ID where you want to deploy.
  * kms_profile = The profile you want to use to issue the deployments. Targets the deployment account.
  * kms_key = A pre-created symmetric KMS key. It's only purpose is for encryption/decryption of deployment secrets.
  * deployment_name = The name of the deployment, used in kubernetes namespace, container naming and datadog "deployment" Unified Tag)
* Run `terraform init` in the infra directory.
* Run `terraform apply` in `infra` directory. This should complete ok. 
  * Check in the console if you see the GKE cluster, Cloud SQL database, etc.
  * If you enabled load balancer deployment, check for the load balancer as well.
  * The configuration values needed for application deployment will be output to the console after the apply completes.

**Application Deployment**: After infrastructure is ready, deploy the application using the datafold-operator. Continue with the [Datafold Helm Charts repository](https://github.com/datafold/helm-charts) to deploy the operator manager and then the application through the operator. The operator is the default and recommended method for deploying Datafold.

## Infrastructure Dependencies

This module is designed to provide the complete infrastructure stack for Datafold deployment. However, if you already have GKE infrastructure in place, you can choose to configure the required resources independently.

**Required Infrastructure Components**:
- GKE cluster with appropriate node pools
- Cloud SQL PostgreSQL database
- GCS bucket for ClickHouse backups
- Persistent disks for persistent storage (ClickHouse data, ClickHouse logs, Redis data)
- IAM roles and service accounts for cluster operations
- Load balancer (optional, can be managed by Google Cloud Load Balancer Controller)
- VPC and networking components
- SSL certificate (validation timing depends on deployment method):
  - **Terraform-managed LB**: Certificate must be pre-created and validated
  - **Kubernetes-managed LB**: Certificate created automatically, validated post-deployment

**Alternative Approaches**:
- **Use this module**: Provides complete infrastructure setup for new deployments
- **Use existing infrastructure**: Configure required resources manually or through other means
- **Hybrid approach**: Use this module for some components and existing infrastructure for others

For detailed specifications of each required component, see the [Datafold Dedicated Cloud GCP Deployment Documentation](https://docs.datafold.com/datafold-deployment/dedicated-cloud/gcp). For application deployment instructions, continue with the [Datafold Helm Charts repository](https://github.com/datafold/helm-charts) to deploy the operator manager and then the application through the operator.

## Detailed Infrastructure Components

Based on the [Datafold GCP Deployment Documentation](https://docs.datafold.com/datafold-deployment/dedicated-cloud/gcp), this module provisions the following detailed infrastructure components:

### Persistent Disks
The Datafold application requires 3 persistent disks for storage, each deployed as encrypted Google Compute Engine persistent disks in the primary availability zone:

- **ClickHouse data disk**: Serves as the analytical database storage for Datafold. ClickHouse is a columnar database that excels at analytical queries. The default 40GB allocation usually provides sufficient space for typical deployments, but it can be scaled up based on data volume requirements.
- **ClickHouse logs disk**: Stores ClickHouse's internal logs and temporary data. The separate logs disk prevents log data from consuming IOPS and I/O performance from actual data storage.
- **Redis data disk**: Provides persistent storage for Redis, which handles task distribution and distributed locks in the Datafold application. Redis is memory-first but benefits from persistence for data durability across restarts.

All persistent disks are encrypted by default using Google-managed encryption keys, ensuring data security at rest.

### Load Balancer
The load balancer serves as the primary entry point for all external traffic to the Datafold application. The module offers 2 deployment strategies:

- **External Load Balancer Deployment** (the default approach): Creates a Google Cloud Load Balancer through Terraform
- **Kubernetes-Managed Load Balancer**: Relies on the Google Cloud Load Balancer Controller running within the GKE cluster, deployed by the datafold application resource. This means Kubernetes creates the load balancer for you.

### GKE Cluster
The Google Kubernetes Engine (GKE) cluster forms the compute foundation for the Datafold application:

- **Network Architecture**: The entire cluster is deployed into private subnets with Cloud NAT for egress traffic
- **Security Features**: Workload Identity, Shielded nodes, Binary authorization, Network policy, and Private nodes
- **Node Management**: Supports up to three managed node pools with automatic scaling

### IAM Roles and Permissions
The IAM architecture follows the principle of least privilege:

- **GKE service account**: Basic permissions for logging, monitoring, and storage access
- **ClickHouse backup service account**: Custom role for ClickHouse to make backups and store them on Cloud Storage
- **Datafold service accounts**: Pre-defined roles for different application components

### Cloud SQL Database
The PostgreSQL Cloud SQL instance serves as the primary relational database:

- **Storage configuration**: Starts with a 20GB initial allocation that can automatically scale up to 100GB
- **High availability**: Intentionally disabled by default to reduce costs and complexity
- **Security and encryption**: Always encrypts data at rest using Google-managed encryption keys

### Initializing the application

After deploying the application through the operator (see the [Datafold Helm Charts repository](https://github.com/datafold/helm-charts)), establish a shell into the `<deployment>-dfshell` container. 
It is likely that the scheduler and server containers are crashing in a loop.

All we need to do is to run these commands:

1. `./manage.py clickhouse create-tables`
2. `./manage.py database create-or-upgrade`
3. `./manage.py installation set-new-deployment-params`

Now all containers should be up and running.

<!-- BEGIN_TF_DOCS -->

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_dns"></a> [dns](#requirement\_dns) | 3.2.1 |
| <a name="requirement_google"></a> [google](#requirement\_google) | >= 4.80.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_google"></a> [google](#provider\_google) | >= 4.80.0 |
| <a name="provider_random"></a> [random](#provider\_random) | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_clickhouse_backup"></a> [clickhouse\_backup](#module\_clickhouse\_backup) | ./modules/clickhouse_backup | n/a |
| <a name="module_database"></a> [database](#module\_database) | ./modules/database | n/a |
| <a name="module_gke"></a> [gke](#module\_gke) | ./modules/gke | n/a |
| <a name="module_load_balancer"></a> [load\_balancer](#module\_load\_balancer) | ./modules/load_balancer | n/a |
| <a name="module_networking"></a> [networking](#module\_networking) | ./modules/networking | n/a |
| <a name="module_project-iam-bindings"></a> [project-iam-bindings](#module\_project-iam-bindings) | terraform-google-modules/iam/google//modules/projects_iam | n/a |
| <a name="module_project_factory_project_services"></a> [project\_factory\_project\_services](#module\_project\_factory\_project\_services) | terraform-google-modules/project-factory/google//modules/project_services | ~> 14.4.0 |

## Resources

| Name | Type |
|------|------|

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_add_onprem_support_group"></a> [add\_onprem\_support\_group](#input\_add\_onprem\_support\_group) | Flag to add onprem support group for datafold-onprem-support@datafold.com | `bool` | `true` | no |
| <a name="input_clickhouse_backup_sa_key"></a> [clickhouse\_backup\_sa\_key](#input\_clickhouse\_backup\_sa\_key) | SA key from secrets | `string` | `""` | no |
| <a name="input_clickhouse_data_disk_size"></a> [clickhouse\_data\_disk\_size](#input\_clickhouse\_data\_disk\_size) | Data volume size clickhouse | `number` | `40` | no |
| <a name="input_clickhouse_db"></a> [clickhouse\_db](#input\_clickhouse\_db) | Db for clickhouse. | `string` | `"clickhouse"` | no |
| <a name="input_clickhouse_gcs_bucket"></a> [clickhouse\_gcs\_bucket](#input\_clickhouse\_gcs\_bucket) | GCS Bucket for clickhouse backups. | `string` | `"clickhouse-backups-abcguo23"` | no |
| <a name="input_clickhouse_get_backup_sa_from_secrets_yaml"></a> [clickhouse\_get\_backup\_sa\_from\_secrets\_yaml](#input\_clickhouse\_get\_backup\_sa\_from\_secrets\_yaml) | Flag to toggle getting clickhouse backup SA from secrets.yaml instead of creating new one | `bool` | `false` | no |
| <a name="input_clickhouse_username"></a> [clickhouse\_username](#input\_clickhouse\_username) | Username for clickhouse. | `string` | `"clickhouse"` | no |
| <a name="input_common_tags"></a> [common\_tags](#input\_common\_tags) | Common tags to apply to any resource | `map(string)` | n/a | yes |
| <a name="input_create_ssl_cert"></a> [create\_ssl\_cert](#input\_create\_ssl\_cert) | True to create the SSL certificate, false if not | `bool` | `false` | no |
| <a name="input_database_name"></a> [database\_name](#input\_database\_name) | The name of the database | `string` | `"datafold"` | no |
| <a name="input_database_version"></a> [database\_version](#input\_database\_version) | Version of the database | `string` | `"POSTGRES_15"` | no |
| <a name="input_datafold_intercom_app_id"></a> [datafold\_intercom\_app\_id](#input\_datafold\_intercom\_app\_id) | The app id for the intercom. A value other than "" will enable this feature. Only used if the customer doesn't use slack. | `string` | `""` | no |
| <a name="input_db_deletion_protection"></a> [db\_deletion\_protection](#input\_db\_deletion\_protection) | A flag that sets delete protection (applied in terraform only, not on the cloud). | `bool` | `true` | no |
| <a name="input_default_node_disk_size"></a> [default\_node\_disk\_size](#input\_default\_node\_disk\_size) | Disk size for a node | `number` | `40` | no |
| <a name="input_deploy_neg_backend"></a> [deploy\_neg\_backend](#input\_deploy\_neg\_backend) | Set this to true to connect the backend service to the NEG that the GKE cluster will create | `bool` | `true` | no |
| <a name="input_deploy_vpc_flow_logs"></a> [deploy\_vpc\_flow\_logs](#input\_deploy\_vpc\_flow\_logs) | Flag weither or not to deploy vpc flow logs | `bool` | `false` | no |
| <a name="input_deployment_name"></a> [deployment\_name](#input\_deployment\_name) | Name of the current deployment. | `string` | n/a | yes |
| <a name="input_domain_name"></a> [domain\_name](#input\_domain\_name) | Provide valid domain name (used to set host in GCP) | `string` | n/a | yes |
| <a name="input_environment"></a> [environment](#input\_environment) | Global environment tag to apply on all datadog logs, metrics, etc. | `string` | n/a | yes |
| <a name="input_gcs_path"></a> [gcs\_path](#input\_gcs\_path) | Path in the GCS bucket to the backups | `string` | `"backups"` | no |
| <a name="input_github_endpoint"></a> [github\_endpoint](#input\_github\_endpoint) | URL of Github enpoint to connect to. Useful for GH Enterprise. | `string` | `""` | no |
| <a name="input_gitlab_endpoint"></a> [gitlab\_endpoint](#input\_gitlab\_endpoint) | URL of Gitlab enpoint to connect to. Useful for GH Enterprise. | `string` | `""` | no |
| <a name="input_host_override"></a> [host\_override](#input\_host\_override) | A valid domain name if they provision their own DNS / routing | `string` | `""` | no |
| <a name="input_lb_app_rules"></a> [lb\_app\_rules](#input\_lb\_app\_rules) | Extra rules to apply to the application load balancer for additional filtering | <pre>list(object({<br>    action         = string<br>    priority       = number<br>    description    = string<br>    match_type     = string       # can be either "src_ip_ranges" or "expr"<br>    versioned_expr = string       # optional, only used if match_type is "src_ip_ranges"<br>    src_ip_ranges  = list(string) # optional, only used if match_type is "src_ip_ranges"<br>    expr           = string       # optional, only used if match_type is "expr"<br>  }))</pre> | n/a | yes |
| <a name="input_lb_layer_7_ddos_defence"></a> [lb\_layer\_7\_ddos\_defence](#input\_lb\_layer\_7\_ddos\_defence) | Flag to toggle layer 7 ddos defence | `bool` | `false` | no |
| <a name="input_legacy_naming"></a> [legacy\_naming](#input\_legacy\_naming) | Flag to toggle legacy behavior - like naming of resources | `bool` | `true` | no |
| <a name="input_mig_disk_type"></a> [mig\_disk\_type](#input\_mig\_disk\_type) | https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance_template#disk_type | `string` | `"pd-balanced"` | no |
| <a name="input_postgres_allocated_storage"></a> [postgres\_allocated\_storage](#input\_postgres\_allocated\_storage) | The amount of allocated storage for the postgres database | `number` | `20` | no |
| <a name="input_postgres_instance"></a> [postgres\_instance](#input\_postgres\_instance) | GCP instance type for PostgreSQL database.<br>Available instance groups: .<br>Available instance classes: . | `string` | `"db-custom-2-7680"` | no |
| <a name="input_postgres_ro_username"></a> [postgres\_ro\_username](#input\_postgres\_ro\_username) | Postgres read-only user name | `string` | `"datafold_ro"` | no |
| <a name="input_postgres_username"></a> [postgres\_username](#input\_postgres\_username) | The username to use for the postgres CloudSQL database | `string` | `"datafold"` | no |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | The project to deploy to, if not set the default provider project is used. | `string` | n/a | yes |
| <a name="input_provider_azs"></a> [provider\_azs](#input\_provider\_azs) | Provider AZs list, if empty we get AZs dynamically | `list(string)` | n/a | yes |
| <a name="input_provider_region"></a> [provider\_region](#input\_provider\_region) | Region for deployment in GCP | `string` | n/a | yes |
| <a name="input_redis_data_size"></a> [redis\_data\_size](#input\_redis\_data\_size) | Redis volume size | `number` | `10` | no |
| <a name="input_remote_storage"></a> [remote\_storage](#input\_remote\_storage) | Type of remote storage for clickhouse backups. | `string` | `"gcs"` | no |
| <a name="input_restricted_roles"></a> [restricted\_roles](#input\_restricted\_roles) | Flag to stop certain IAM related resources from being updated/changed | `bool` | `false` | no |
| <a name="input_restricted_viewer_role"></a> [restricted\_viewer\_role](#input\_restricted\_viewer\_role) | Flag to stop certain IAM related resources from being updated/changed | `bool` | `false` | no |
| <a name="input_ssl_cert_name"></a> [ssl\_cert\_name](#input\_ssl\_cert\_name) | Provide valid SSL certificate name in GCP OR ssl\_private\_key\_path and ssl\_cert\_path | `string` | `""` | no |
| <a name="input_ssl_cert_path"></a> [ssl\_cert\_path](#input\_ssl\_cert\_path) | SSL certificate path | `string` | `""` | no |
| <a name="input_ssl_private_key_path"></a> [ssl\_private\_key\_path](#input\_ssl\_private\_key\_path) | Private SSL key path | `string` | `""` | no |
| <a name="input_vpc_cidr"></a> [vpc\_cidr](#input\_vpc\_cidr) | Network CIDR for VPC | `string` | `"10.0.0.0/16"` | no |
| <a name="input_vpc_flow_logs_interval"></a> [vpc\_flow\_logs\_interval](#input\_vpc\_flow\_logs\_interval) | Interval for vpc flow logs | `string` | `"INTERVAL_5_SEC"` | no |
| <a name="input_vpc_flow_logs_sampling"></a> [vpc\_flow\_logs\_sampling](#input\_vpc\_flow\_logs\_sampling) | Sampling for vpc flow logs | `string` | `"0.5"` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | Provide ID of existing VPC if you want to omit creation of new one | `string` | `""` | no |
| <a name="input_vpc_master_cidr_block"></a> [vpc\_master\_cidr\_block](#input\_vpc\_master\_cidr\_block) | cidr block for k8s master, must be a /28 block. | `string` | `"192.168.0.0/28"` | no |
| <a name="input_vpc_secondary_cidr_pods"></a> [vpc\_secondary\_cidr\_pods](#input\_vpc\_secondary\_cidr\_pods) | Network CIDR for VPC secundary subnet 1 | `string` | `"/17"` | no |
| <a name="input_vpc_secondary_cidr_services"></a> [vpc\_secondary\_cidr\_services](#input\_vpc\_secondary\_cidr\_services) | Network CIDR for VPC secundary subnet 2 | `string` | `"/17"` | no |
| <a name="input_whitelist_all_ingress_cidrs_lb"></a> [whitelist\_all\_ingress\_cidrs\_lb](#input\_whitelist\_all\_ingress\_cidrs\_lb) | Normally we filter on the load balancer, but some customers want to filter at the SG/Firewall. This flag will whitelist 0.0.0.0/0 on the load balancer. | `bool` | `false` | no |
| <a name="input_whitelisted_egress_cidrs"></a> [whitelisted\_egress\_cidrs](#input\_whitelisted\_egress\_cidrs) | List of Internet addresses to which the application has access | `list(string)` | n/a | yes |
| <a name="input_whitelisted_ingress_cidrs"></a> [whitelisted\_ingress\_cidrs](#input\_whitelisted\_ingress\_cidrs) | List of CIDRs that can access the HTTP/HTTPS | `list(string)` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_clickhouse_backup_sa"></a> [clickhouse\_backup\_sa](#output\_clickhouse\_backup\_sa) | Name of the clickhouse backup Service Account |
| <a name="output_clickhouse_data_size"></a> [clickhouse\_data\_size](#output\_clickhouse\_data\_size) | Size in GB of the clickhouse data volume |
| <a name="output_clickhouse_data_volume_id"></a> [clickhouse\_data\_volume\_id](#output\_clickhouse\_data\_volume\_id) | Volume ID of the clickhouse data PD volume |
| <a name="output_clickhouse_gcs_bucket"></a> [clickhouse\_gcs\_bucket](#output\_clickhouse\_gcs\_bucket) | Name of the GCS bucket for the clickhouse backups |
| <a name="output_clickhouse_logs_size"></a> [clickhouse\_logs\_size](#output\_clickhouse\_logs\_size) | Size in GB of the clickhouse logs volume |
| <a name="output_clickhouse_logs_volume_id"></a> [clickhouse\_logs\_volume\_id](#output\_clickhouse\_logs\_volume\_id) | Volume ID of the clickhouse logs PD volume |
| <a name="output_clickhouse_password"></a> [clickhouse\_password](#output\_clickhouse\_password) | Password to use for clickhouse |
| <a name="output_cloud_provider"></a> [cloud\_provider](#output\_cloud\_provider) | The cloud provider creating all the resources |
| <a name="output_cluster_name"></a> [cluster\_name](#output\_cluster\_name) | The name of the GKE cluster that was created |
| <a name="output_db_instance_id"></a> [db\_instance\_id](#output\_db\_instance\_id) | The database instance ID |
| <a name="output_deployment_name"></a> [deployment\_name](#output\_deployment\_name) | The name of the deployment |
| <a name="output_domain_name"></a> [domain\_name](#output\_domain\_name) | The domain name on the HTTPS certificate |
| <a name="output_lb_external_ip"></a> [lb\_external\_ip](#output\_lb\_external\_ip) | The load balancer IP when it was provisioned. |
| <a name="output_neg_name"></a> [neg\_name](#output\_neg\_name) | The name of the Network Endpoint Group where pods need to be registered from kubernetes. |
| <a name="output_postgres_database_name"></a> [postgres\_database\_name](#output\_postgres\_database\_name) | The name of the postgres database |
| <a name="output_postgres_host"></a> [postgres\_host](#output\_postgres\_host) | The hostname of the postgres database |
| <a name="output_postgres_password"></a> [postgres\_password](#output\_postgres\_password) | The postgres password |
| <a name="output_postgres_port"></a> [postgres\_port](#output\_postgres\_port) | The port of the postgres database |
| <a name="output_postgres_username"></a> [postgres\_username](#output\_postgres\_username) | The postgres username |
| <a name="output_redis_data_size"></a> [redis\_data\_size](#output\_redis\_data\_size) | The size in GB of the redis data volume |
| <a name="output_redis_data_volume_id"></a> [redis\_data\_volume\_id](#output\_redis\_data\_volume\_id) | The volume ID of the Redis PD data volume |
| <a name="output_redis_password"></a> [redis\_password](#output\_redis\_password) | The Redis password |
| <a name="output_vpc_cidr"></a> [vpc\_cidr](#output\_vpc\_cidr) | The CIDR range of the VPC |
| <a name="output_vpc_id"></a> [vpc\_id](#output\_vpc\_id) | The ID of the Google VPC the cluster runs in. |
| <a name="output_vpc_subnetwork"></a> [vpc\_subnetwork](#output\_vpc\_subnetwork) | The subnet in which the cluster is created |

<!-- END_TF_DOCS -->
