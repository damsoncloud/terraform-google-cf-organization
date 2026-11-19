output "policies" {
  description = "Names of the policies set (`<parent>/policies/<constraint>`), by `<parent>/<constraint>`."
  value       = { for key, policy in google_org_policy_policy.policies : key => policy.name }
}
