# Enforced on the Model Armour templates of every project in the organisation. The Agent Platform and Google MCP server integrations can only be set on projects, by
# cf-gcp-project, with the same filters (the `model_armor` output).
resource "google_model_armor_floorsetting" "organization" {
  parent                           = "organizations/${var.organization_id}"
  location                         = "global"
  enable_floor_setting_enforcement = var.model_armor.enforcement

  filter_config {
    dynamic "rai_settings" {
      for_each = length(var.model_armor.responsible_ai_filters) > 0 ? [var.model_armor.responsible_ai_filters] : []

      content {
        dynamic "rai_filters" {
          for_each = rai_settings.value

          content {
            filter_type      = rai_filters.value
            confidence_level = var.model_armor.confidence_level
          }
        }
      }
    }

    pi_and_jailbreak_filter_settings {
      filter_enforcement = var.model_armor.prompt_injection_and_jailbreak ? "ENABLED" : "DISABLED"
      confidence_level   = var.model_armor.confidence_level
    }

    malicious_uri_filter_settings {
      filter_enforcement = var.model_armor.malicious_uri ? "ENABLED" : "DISABLED"
    }

    sdp_settings {
      basic_config {
        filter_enforcement = var.model_armor.sensitive_data_protection ? "ENABLED" : "DISABLED"
      }
    }
  }

  floor_setting_metadata {
    multi_language_detection {
      enable_multi_language_detection = var.model_armor.multi_language_detection
    }
  }
}
