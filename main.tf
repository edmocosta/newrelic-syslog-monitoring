provider "newrelic" {
  account_id = var.NEWRELIC_ACCOUNT_ID
  api_key    = var.NEWRELIC_API_KEY
  region     = "Staging"
}