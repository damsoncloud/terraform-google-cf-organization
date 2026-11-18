# Organisation policies

Submodule of [cf-organization](../../README.md) setting the organisation policies of the Cloud Foundations, applied in the cf-organization state and called directly by the
customer repository:

* the baseline on the organisation: resource locations, service usage, VPC peering, Shared VPC host projects, the members allowed in IAM allow policies, and the managed
  constraints for service account keys, Compute Engine, Dataflow and Spanner,
* the exceptions of the `legacy` folder (service usage and service account key creation) and of the API Management Hub project (the API keys and Gemini APIs),
* further policies replacing or extending the baseline.

The `mode` input supports a dry-run before the policies are enforced: `dry_run` sets only the policies whose constraints support dry-run, i.e. managed and custom constraints
and `gcp.restrictServiceUsage`, as dry-run policies, whose violations are recorded in the audit logs; `enforced` enforces all policies.

## Usage

```hcl
module "org_policies" {
  source  = "damsoncloud/cf-organization/google//modules/org-policies"
  version = "X.Y.Z"

  organization_id  = "123456789012"
  mode             = "enforced"
  legacy_folder_id = module.hierarchy.folders["legacy"].id
  api_management = {
    project_id = module.organization.api_management_project_id
  }
}
```

<!-- BEGIN_TF_DOCS -->
<!-- markdownlint-capture -->
<!-- markdownlint-disable MD013 -->
## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| additional\_allowed\_members | Principals allowed in IAM allow policies by the `iam.managed.allowedPolicyMembers` constraint, e.g. `user:someone@partner.example`, in addition to the organisation's principal set and `billing-budget-alert@system.gserviceaccount.com`. | `list(string)` | `[]` | no |
| additional\_allowed\_principal\_sets | Principal sets allowed in IAM allow policies by the `iam.managed.allowedPolicyMembers` constraint, e.g. another organisation's `//cloudresourcemanager.googleapis.com/organizations/<id>`, in addition to the organisation's. | `list(string)` | `[]` | no |
| additional\_allowed\_services | Services allowed by the `gcp.restrictServiceUsage` constraint in the organisation in addition to `allowed_services`. | `list(string)` | `[]` | no |
| additional\_policies | Further policies, replacing the baseline's policy of the same constraint on the same resource: `constraint`, the constraint's name, e.g. `custom.denyExternalBuckets`; `parent`, the resource, `organizations/<id>`, `folders/<id>` or `projects/<id>`, the organisation when null; `enforce`, for boolean constraints, managed constraints included; `parameters`, the parameters of a managed constraint, JSON-encoded, e.g. `jsonencode({ allowedPreviewFeatures = [] })`; `allow` and `deny`, the values of a list constraint, `allow_all` and `deny_all` to allow or deny all values; `inherit_from_parent`, whether a list policy is merged with its parent's. | ```list(object({ constraint = string parent = optional(string) enforce = optional(bool) parameters = optional(string) allow = optional(list(string), []) deny = optional(list(string), []) allow_all = optional(bool, false) deny_all = optional(bool, false) inherit_from_parent = optional(bool, false) }))``` | `[]` | no |
| allowed\_locations | Values of the `gcp.resourceLocations` constraint: the locations where resources can be created, e.g. the primary and DR regions' value groups. | `list(string)` | ```[ "in:europe-west4-locations" ]``` | no |
| allowed\_services | Services allowed by the `gcp.restrictServiceUsage` constraint in the organisation. Services the constraint does not support are always allowed. | `list(string)` | ```[ "agentidentity.googleapis.com", "agentidentitycredentials.googleapis.com", "agentregistry.googleapis.com", "agentregistryendpoint.googleapis.com", "aiplatform.googleapis.com", "artifactregistry.googleapis.com", "bigquery.googleapis.com", "bigquerybiengine.googleapis.com", "bigqueryconnection.googleapis.com", "bigquerydatapolicy.googleapis.com", "bigquerydatatransfer.googleapis.com", "bigquerymigration.googleapis.com", "bigqueryreservation.googleapis.com", "bigqueryscripts.googleapis.com", "bigquerystorage.googleapis.com", "bigtable.googleapis.com", "bigtableadmin.googleapis.com", "bigtableclusteradmin.googleapis.com", "bigtabletableadmin.googleapis.com", "binaryauthorization.googleapis.com", "cloudaicompanion.googleapis.com", "cloudbuild.googleapis.com", "clouddeploy.googleapis.com", "clouderrorreporting.googleapis.com", "cloudkms.googleapis.com", "cloudprofiler.googleapis.com", "cloudscheduler.googleapis.com", "cloudtasks.googleapis.com", "cloudtrace.googleapis.com", "compute.googleapis.com", "container.googleapis.com", "containeranalysis.googleapis.com", "containerfilesystem.googleapis.com", "containersecurity.googleapis.com", "containerthreatdetection.googleapis.com", "dataflow.googleapis.com", "dataform.googleapis.com", "datafusion.googleapis.com", "datastore.googleapis.com", "datastream.googleapis.com", "datastudio.googleapis.com", "documentai.googleapis.com", "eventarc.googleapis.com", "iap.googleapis.com", "identityplatform.googleapis.com", "memorystore.googleapis.com", "modelarmor.googleapis.com", "notebooks.googleapis.com", "osconfig.googleapis.com", "oslogin.googleapis.com", "policyanalyzer.googleapis.com", "policysimulator.googleapis.com", "privilegedaccessmanager.googleapis.com", "pubsub.googleapis.com", "pubsublite.googleapis.com", "recaptchaenterprise.googleapis.com", "recommender.googleapis.com", "redis.googleapis.com", "run.googleapis.com", "secretmanager.googleapis.com", "securitycenter.googleapis.com", "securitycentermanagement.googleapis.com", "servicedirectory.googleapis.com", "servicehealth.googleapis.com", "spanner.googleapis.com", "sqladmin.googleapis.com", "storage.googleapis.com", "storagebatchoperations.googleapis.com", "storageinsights.googleapis.com", "storagetransfer.googleapis.com", "texttospeech.googleapis.com", "threatdetection.googleapis.com", "translate.googleapis.com", "vectorsearch.googleapis.com", "workflows.googleapis.com", "workloadidentity.googleapis.com" ]``` | no |
| allowed\_vpc\_peering\_networks | Values of the `compute.restrictVpcPeering` constraint: the networks VPC networks may peer with, e.g. `under:organizations/<id>`; peering is denied when empty. | `list(string)` | `[]` | no |
| api\_management | The API Management Hub project, e.g. the `api_management_project_id` output of cf-organization, and the services allowed there in addition to the organisation's, e.g. the Gemini API; no exception when null. | ```object({ project_id = string allowed_services = optional(list(string), ["apikeys.googleapis.com", "generativelanguage.googleapis.com"]) })``` | `null` | no |
| disabled\_constraints | Constraints of the organisation-level baseline not to set, e.g. `compute.managed.vmExternalIpAccess`. | `list(string)` | `[]` | no |
| legacy\_folder\_id | The `legacy` folder (`folders/<id>`), e.g. the `folders["legacy"].id` output of cf-hierarchy, where service usage and service account key creation are not restricted; no exceptions when null. | `string` | `null` | no |
| mode | `dry_run` sets only the policies whose constraints support dry-run, as dry-run policies; `enforced` enforces all policies. | `string` | n/a | yes |
| organization\_id | ID of the organisation, where the baseline policies are set. | `string` | n/a | yes |
| shared\_vpc\_host\_folder\_id | The folder (`folders/<id>`) where Shared VPC host projects can be, e.g. the common environment's folder, enforced with `compute.restrictSharedVpcHostProjects`; not restricted when null. | `string` | `null` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| policies | Names of the policies set (`<parent>/policies/<constraint>`), by `<parent>/<constraint>`. |
<!-- markdownlint-restore -->
<!-- END_TF_DOCS -->
