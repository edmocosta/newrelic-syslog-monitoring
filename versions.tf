terraform {
  required_version = ">= 0.13"

  required_providers {
    newrelic = {
      source  = "newrelic/newrelic"
      version = ">= 2.12.0"
    }
  }
}