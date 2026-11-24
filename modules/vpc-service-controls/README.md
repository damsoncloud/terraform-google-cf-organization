# VPC Service Controls

Submodule of [cf-organization](../../README.md) setting up VPC Service Controls, applied in the cf-organization state and called directly by the customer repository:

* the organisation's access policy, unless an existing one is given; the perimeter is added to it, and its other perimeters are left as they are,
* a regular perimeter restricting the generally available supported services which the organisation allows or the foundations use,
* ingress rules for the deployers, e.g. from GitHub-hosted runners, for the foundations' groups, e.g. the organisation administrators and the SREs and viewers of the common
  and production environments, from any source, and for Cloud Billing's budget notifications, and further access levels, ingress and egress rules,
* the membership of the given projects, e.g. the bootstrap and common projects.

The modules creating the other projects in the perimeter, e.g. those of the `production` folder, add them with the `perimeter_name` output, to both the enforced and the
dry-run configuration, using the `google_access_context_manager_service_perimeter_resource` and `google_access_context_manager_service_perimeter_dry_run_resource` resources.
The modules owning flows into the perimeter, e.g. cf-observability's organisation-level log sink, add their ingress rules the same way, with the
`google_access_context_manager_service_perimeter_ingress_policy` and `google_access_context_manager_service_perimeter_dry_run_ingress_policy` resources; the former only in
`enforced` mode, as this submodule does with its own rules.

The `mode` input supports a dry-run before the perimeter is enforced: the dry-run configuration always holds the restrictions and rules, whose violations are recorded in the audit
logs; in `dry_run` mode, the enforced configuration holds the projects but restricts no service. A project can only be in one regular perimeter, so adding a project which is
already in another perimeter fails.

## Usage

```hcl
module "vpc_service_controls" {
  source  = "damsoncloud/cf-organization/google//modules/vpc-service-controls"
  version = "X.Y.Z"

  organization_id = "123456789012"
  mode            = "enforced"
  projects = {
    bootstrap      = module.bootstrap.project_number
    observability  = module.organization.observability_project_number
    api_management = module.organization.api_management_project_number
  }
  deployers = concat(
    [module.bootstrap.tf_bootstrap_email, module.bootstrap.tf_plan_email],
    values(module.bootstrap.tf_environment_emails),
  )
  groups = module.organization.perimeter_groups
}
```

<!-- BEGIN_TF_DOCS -->
<!-- markdownlint-capture -->
<!-- markdownlint-disable MD013 -->
## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| access\_levels | Basic access levels created in the access policy, by name, for the sources of `ingress_policies`:   the requests' `ip_subnetworks`, `members` and `regions`, all of which must match. | ```map(object({ ip_subnetworks = optional(list(string), []) members = optional(list(string), []) regions = optional(list(string), []) }))``` | `{}` | no |
| access\_policy\_id | ID of the organisation's existing access policy, of which there can be only one; the perimeter is added to it, and its other perimeters are left as they are. An access policy is created when null. | `string` | `null` | no |
| additional\_restricted\_services | Services restricted by the perimeter in addition to `restricted_services`. | `list(string)` | `[]` | no |
| deployers | Emails of the service accounts deploying from outside the perimeter, e.g. GitHub-hosted runners, allowed to access the perimeter from any source: `tf-bootstrap`, `tf-plan` and the environment deployers of cf-bootstrap. | `list(string)` | `[]` | no |
| egress\_policies | Egress rules:   `identities` or `identity_type`, the principals allowed;   `resources`, the projects outside the perimeter, e.g. `projects/<number>`, `*` for all, and `external_resources`, e.g. Amazon S3 buckets;   `operations`, the methods by service, as in `ingress_policies`. | ```list(object({ title = optional(string) identities = optional(list(string), []) identity_type = optional(string) resources = optional(list(string), []) external_resources = optional(list(string), []) operations = optional(map(list(string)), { "*" = [] }) }))``` | `[]` | no |
| groups | Emails of the groups whose members access the perimeter's projects from outside it, from any source, e.g. the `perimeter_groups` output of cf-organization. For a stricter access, e.g. from the office network or managed devices only, leave it empty and use `access_levels` and `ingress_policies` instead. | `list(string)` | `[]` | no |
| ingress\_policies | Ingress rules in addition to the deployers', the foundations' groups' and Cloud Billing's, by their unique `title`:   `identities` or `identity_type` (`ANY_IDENTITY`, `ANY_USER_ACCOUNT` or `ANY_SERVICE_ACCOUNT`), the principals allowed;   `source_access_levels`, the names of `access_levels` or `*` for any source, and `source_resources`, e.g. `projects/<number>`;   `resources`, the projects in the perimeter, `*` for all;   `operations`, the methods by service, `*` for all services, and all methods of a service when its list is empty. | ```list(object({ title = string identities = optional(list(string), []) identity_type = optional(string) source_access_levels = optional(list(string), []) source_resources = optional(list(string), []) resources = optional(list(string), ["*"]) operations = optional(map(list(string)), { "*" = [] }) }))``` | `[]` | no |
| mode | `dry_run` sets the restrictions and rules in the perimeter's dry-run configuration only, whose violations are recorded in the audit logs; `enforced` also enforces them. | `string` | n/a | yes |
| organization\_id | ID of the organisation, the parent of the access policy created when `access_policy_id` is null. | `string` | n/a | yes |
| perimeter\_name | Short name of the perimeter, unique in the access policy. | `string` | `"cloud_foundations_production"` | no |
| projects | Numbers of the projects in the perimeter, by a static key, e.g. the bootstrap and common projects; the modules creating the other projects add them with the `perimeter_name` output. | `map(string)` | `{}` | no |
| restricted\_services | Services restricted by the perimeter: by default, the generally available services supported by VPC Service Controls among the services allowed by the org-policies submodule and those used by the foundations. | `list(string)` | ```[ "agentidentity.googleapis.com", "agentidentitycredentials.googleapis.com", "agentregistry.googleapis.com", "aiplatform.googleapis.com", "apikeys.googleapis.com", "artifactregistry.googleapis.com", "bigquery.googleapis.com", "bigquerydatapolicy.googleapis.com", "bigquerydatatransfer.googleapis.com", "bigquerymigration.googleapis.com", "bigtable.googleapis.com", "binaryauthorization.googleapis.com", "cloudaicompanion.googleapis.com", "cloudasset.googleapis.com", "cloudbuild.googleapis.com", "clouddeploy.googleapis.com", "clouderrorreporting.googleapis.com", "cloudfunctions.googleapis.com", "cloudkms.googleapis.com", "cloudprofiler.googleapis.com", "cloudscheduler.googleapis.com", "cloudtasks.googleapis.com", "cloudtrace.googleapis.com", "compute.googleapis.com", "container.googleapis.com", "containeranalysis.googleapis.com", "containerfilesystem.googleapis.com", "containersecurity.googleapis.com", "containerthreatdetection.googleapis.com", "dataflow.googleapis.com", "dataform.googleapis.com", "datafusion.googleapis.com", "datastream.googleapis.com", "dns.googleapis.com", "documentai.googleapis.com", "essentialcontacts.googleapis.com", "eventarc.googleapis.com", "iamcredentials.googleapis.com", "iap.googleapis.com", "logging.googleapis.com", "memorystore.googleapis.com", "modelarmor.googleapis.com", "monitoring.googleapis.com", "notebooks.googleapis.com", "orgpolicy.googleapis.com", "osconfig.googleapis.com", "oslogin.googleapis.com", "policysimulator.googleapis.com", "privilegedaccessmanager.googleapis.com", "pubsub.googleapis.com", "pubsublite.googleapis.com", "recaptchaenterprise.googleapis.com", "recommender.googleapis.com", "redis.googleapis.com", "run.googleapis.com", "secretmanager.googleapis.com", "securitycenter.googleapis.com", "securitycentermanagement.googleapis.com", "servicedirectory.googleapis.com", "servicehealth.googleapis.com", "servicenetworking.googleapis.com", "serviceusage.googleapis.com", "spanner.googleapis.com", "sqladmin.googleapis.com", "storage.googleapis.com", "storagebatchoperations.googleapis.com", "storageinsights.googleapis.com", "storagetransfer.googleapis.com", "sts.googleapis.com", "texttospeech.googleapis.com", "translate.googleapis.com", "vectorsearch.googleapis.com", "workflows.googleapis.com", "workloadidentity.googleapis.com" ]``` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| access\_policy\_id | ID of the organisation's access policy. |
| perimeter\_name | Resource name of the perimeter (`accessPolicies/<id>/servicePerimeters/<name>`), for the modules adding their projects and ingress rules to its enforced and dry-run configurations. |
<!-- markdownlint-restore -->
<!-- END_TF_DOCS -->
