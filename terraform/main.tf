terraform {
  backend "gcs" {
    bucket = "moonpay-ftstore"
    prefix = "terraform/state"
  }
}

data "google_project" "project" {
  project_id = "moonpay-assignment"
}

variable "image_tag" {
  default = "latest"
}

variable "typeorm_password" {
  default = ""
}

resource "google_secret_manager_secret" "typeorm_password_secret" {

  project   = data.google_project.project.project_id
  secret_id = "typeorm_password"
  replication {
    automatic = true
  }
}

resource "google_secret_manager_secret_version" "secret-version-data" {

  secret      = google_secret_manager_secret.typeorm_password_secret.name
  secret_data = "${var.typeorm_password}"
}

resource "google_secret_manager_secret_iam_member" "secret-access" {

  secret_id  = google_secret_manager_secret.typeorm_password_secret.id
  role       = "roles/secretmanager.secretAccessor"
  member     = "serviceAccount:${data.google_project.project.number}-compute@developer.gserviceaccount.com"
  depends_on = [google_secret_manager_secret.typeorm_password_secret]
}

resource "google_cloud_run_service" "nestjs" {
  provider = google-beta

  name     = "nestjs-test2"
  location = "europe-west1"
  project  = "moonpay-assignment"

  metadata {
    annotations = {
      "run.googleapis.com/launch-stage" = "BETA"
    }
  }

  template {
    spec {
      service_account_name = "${data.google_project.project.number}-compute@developer.gserviceaccount.com"
      containers {
        image = "gcr.io/moonpay-assignment/nestjs-test:${var.image_tag}"
        ports {
          name           = "http1"
          container_port = "3000"
        }
        env {
          name = "TYPEORM_PASSWORD"
          value_from {
            secret_key_ref {
              name = "${google_secret_manager_secret.typeorm_password_secret.secret_id}"
              key  = "1"
            }
          }
        }
        env {
          name  = "TYPEORM_CONNECTION"
          value = "postgres"
        }
        env {
          name  = "TYPEORM_HOST"
          value = "35.195.218.32"
        }
        env {
          name  = "TYPEORM_USERNAME"
          value = "postgres"
        }
        env {
          name  = "TYPEORM_DATABASE"
          value = "postgres"
        }
        env {
          name  = "TYPEORM_PORT"
          value = "5432"
        }
        env {
          name  = "TYPEORM_SYNCHRONIZE"
          value = "true"
        }
        env {
          name  = "TYPEORM_LOGGING"
          value = "true"
        }
        env {
          name  = "TYPEORM_ENTITIES"
          value = "src/**/**.entity.js,src/**/**.entity.ts"
        }
      }
    }
  }

  lifecycle {
    ignore_changes = [
      metadata.0.annotations,
    ]
  }
}

data "google_iam_policy" "noauth" {
  binding {
    role = "roles/run.invoker"
    members = [
      "allUsers",
    ]
  }
}

resource "google_cloud_run_service_iam_policy" "noauth" {
  location = google_cloud_run_service.nestjs.location
  project  = google_cloud_run_service.nestjs.project
  service  = google_cloud_run_service.nestjs.name

  policy_data = data.google_iam_policy.noauth.policy_data
}
