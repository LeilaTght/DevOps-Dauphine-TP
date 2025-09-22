terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.40" # ou récent
    }



    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }



  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}
