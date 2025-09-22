variable "project_id" {
  type        = string
  description = "ID du projet GCP"
}

variable "region" {
  type        = string
  description = "Région GCP (ex: europe-west1)"
}

variable "image_url" {
  type        = string
  description = "URL de l'image Docker dans Artifact Registry"
}

