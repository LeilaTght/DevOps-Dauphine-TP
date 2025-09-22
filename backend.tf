provider "google" {
  project = "ascendant-pad-472521-g7"   # <= le PROJECT_ID
}

terraform {
  backend "gcs" {
    bucket = "ascendant-pad-472521-g7-tf-state-leila"  # <= le bucket créé
    prefix = "terraform/state"
  }
}
