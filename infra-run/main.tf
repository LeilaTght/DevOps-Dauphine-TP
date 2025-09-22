########################################
#  Provider Kubernetes (connexion au cluster GKE)
########################################

data "google_client_config" "default" {}

data "google_container_cluster" "my_cluster" {
  name     = "gke-dauphine"  # Nom du cluster créé dans la partie 1
  location = "us-central1-a" # Zone du cluster
}

provider "kubernetes" {
  host  = data.google_container_cluster.my_cluster.endpoint
  token = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(
    data.google_container_cluster.my_cluster.master_auth[0].cluster_ca_certificate
  )
}

########################################
#  MySQL sur Kubernetes
########################################

resource "kubernetes_deployment" "mysql" {
  metadata {
    name = "mysql"
  }
  spec {
    replicas = 1
    selector {
      match_labels = { app = "mysql" }
    }
    template {
      metadata { labels = { app = "mysql" } }
      spec {
        container {
          name  = "mysql"
          image = "mysql:5.7"

          env {
            name  = "MYSQL_ROOT_PASSWORD"
            value = "rootpassword"
          }
          env {
            name  = "MYSQL_DATABASE"
            value = "wordpress"
          }
          env {
            name  = "MYSQL_USER"
            value = "wordpress"
          }
          env {
            name  = "MYSQL_PASSWORD"
            value = "ilovedevops"
          }

          port {
            container_port = 3306
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "mysql" {
  metadata {
    name = "mysql"
  }
  spec {
    selector = { app = "mysql" }
    port {
      port        = 3306
      target_port = 3306
    }
    type = "ClusterIP"
  }
}

########################################
#  WordPress sur Kubernetes
########################################

resource "kubernetes_deployment" "wordpress" {
  metadata {
    name = "wordpress"
  }
  spec {
    replicas = 1
    selector {
      match_labels = { app = "wordpress" }
    }
    template {
      metadata { labels = { app = "wordpress" } }
      spec {
        container {
          name  = "wordpress"
          image = "wordpress:latest"

          env {
            name  = "WORDPRESS_DB_HOST"
            value = "mysql"
          }
          env {
            name  = "WORDPRESS_DB_USER"
            value = "wordpress"
          }
          env {
            name  = "WORDPRESS_DB_PASSWORD"
            value = "ilovedevops"
          }
          env {
            name  = "WORDPRESS_DB_NAME"
            value = "wordpress"
          }

          port {
            container_port = 80
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "wordpress" {
  metadata {
    name = "wordpress"
  }
  spec {
    selector = { app = "wordpress" }
    port {
      port        = 80
      target_port = 80
    }
    type = "LoadBalancer"
  }
}

########################################
#  Cloud Run (déploiement WordPress custom)
########################################

resource "google_cloud_run_service" "default" {
  name     = "serveur-wordpress"
  location = var.region

  template {
    spec {
      containers {
        image = var.image_url
        ports {
          name           = "http1"
          container_port = 80
        }

        # Exemple si tu veux surclasser les ENV :
        # env { name = "WORDPRESS_DB_HOST"     value = "104.198.78.5" }
        # env { name = "WORDPRESS_DB_USER"     value = "wordpress" }
        # env { name = "WORDPRESS_DB_PASSWORD" value = "ilovedevops" }
        # env { name = "WORDPRESS_DB_NAME"     value = "wordpress" }
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }
}

# Accès public (allUsers = invoker)
data "google_iam_policy" "noauth" {
  binding {
    role    = "roles/run.invoker"
    members = ["allUsers"]
  }
}

resource "google_cloud_run_service_iam_policy" "noauth" {
  location    = google_cloud_run_service.default.location
  project     = google_cloud_run_service.default.project
  service     = google_cloud_run_service.default.name
  policy_data = data.google_iam_policy.noauth.policy_data
}

# Droit de pull Artifact Registry
data "google_project" "current" {}

resource "google_project_iam_member" "ar_reader_for_run" {
  project = var.project_id
  role    = "roles/artifactregistry.reader"
  member  = "serviceAccount:${data.google_project.current.number}-compute@developer.gserviceaccount.com"
}

########################################
#  Outputs pratiques
########################################

output "cloud_run_url" {
  value = google_cloud_run_service.default.status[0].url
}

output "wordpress_lb_ip" {
  value       = try(kubernetes_service.wordpress.status[0].load_balancer[0].ingress[0].ip, null)
  description = "IP publique du WordPress déployé sur GKE"
}
