resource "kubernetes_namespace_v1" "main" {
  metadata {
    annotations = {
      name = local.namespace_name
    }
    name = local.namespace_name
  }
  depends_on = [
    azurerm_kubernetes_cluster.landingzone,
  ]
}

#  resource "kubernetes_secret_v1" "postgres" {
#    metadata {
#      name      = "postgres-secrets"
#      namespace = kubernetes_namespace_v1.main.metadata.0.name
#    }
#    data = {
#      POSTGRES_USER     = "admin"
#      POSTGRES_PASSWORD = "P4ssw0rd"
#    }
#    depends_on = [
#      azurerm_kubernetes_cluster.landingzone,
#    ]
#  }

#  resource "kubernetes_secret_v1" "storage" {
#    metadata {
#      name = "storage-secret"
#    }
#    data = {
#      azure_storage_account_name = local.storage_account_name_aks
#      key                        = azurerm_storage_account.main.primary_access_key
#    }
#    depends_on = [
#      azurerm_kubernetes_cluster.landingzone,
#    ]
#  }

#  resource "kubernetes_persistent_volume_v1" "postgres" {
#    metadata {
#      name = "postgrespers"
#    }
#    spec {
#      capacity = {
#        storage = "100Mi"
#      }
#      access_modes = ["ReadWriteOnce"]
#      persistent_volume_source {
#        azure_file {
#          read_only   = false
#          secret_name = kubernetes_secret_v1.storage.metadata.0.name
#          share_name  = local.share_name
#        }
#      }
#    }
#    depends_on = [
#      azurerm_kubernetes_cluster.landingzone,
#      azurerm_storage_account.main
#    ]
#  }

#  resource "kubernetes_persistent_volume_claim_v1" "postgres" {
#    metadata {
#      name      = "postgrespersclaim"
#      namespace = kubernetes_namespace_v1.main.metadata.0.name
#    }
#    spec {
#      access_modes = ["ReadWriteOnce"]
#      resources {
#        requests = {
#          storage = "100Mi"
#        }
#      }
#      volume_name = kubernetes_persistent_volume_v1.postgres.metadata.0.name
#    }
#    wait_until_bound = false

#    depends_on = [
#      azurerm_kubernetes_cluster.landingzone,
#      kubernetes_persistent_volume_v1.postgres
#    ]
#  }

#  resource "kubernetes_deployment_v1" "postgres" {
#    metadata {
#      name      = "postgres"
#      namespace = kubernetes_namespace_v1.main.metadata.0.name
#    }

#    spec {
#      replicas = 1

#      selector {
#        match_labels = {
#          app = "postgres"
#        }
#      }

#      template {
#        metadata {
#          labels = {
#            app = "postgres"
#          }
#        }

#        spec {
#          container {
#            image = "postgres:latest"
#            name  = "postgres"
#            port {
#              container_port = "5432"
#            }
#            env_from {
#              secret_ref {
#                name = kubernetes_secret_v1.postgres.metadata.0.name
#              }
#            }
#             volume_mount {  #Then this
#               mount_path = "/var/lib/postgresql/data"
#               name       = kubernetes_persistent_volume_v1.postgres.metadata.0.name
#             }
#          }
#           volume {  # First this
#             name = kubernetes_persistent_volume_v1.postgres.metadata.0.name
#             persistent_volume_claim {
#               claim_name = kubernetes_persistent_volume_claim_v1.postgres.metadata.0.name
#             }
#           }
#        }

#      }
#    }
#    depends_on = [
#      azurerm_kubernetes_cluster.landingzone,
#      azurerm_storage_share.main,
#      kubernetes_persistent_volume_v1.postgres,
#      kubernetes_persistent_volume_claim_v1.postgres
#    ]
#  }

resource "kubernetes_deployment_v1" "backstage" {
  metadata {
    name      = "backstage"
    namespace = kubernetes_namespace_v1.main.metadata.0.name
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "backstage"
      }
    }

    template {
      metadata {
        labels = {
          app = "backstage"
        }
      }

      spec {
        container {
          image = "acrregistrybddsj.azurecr.io/backstage:1.0.0"
          # image = "roadiehq/community-backstage-image:latest"
          name = "backstage"
          port {
            name           = "http"
            container_port = "7007"
          }
          #   env_from {
          #     secret_ref {
          #       name = kubernetes_secret_v1.postgres.metadata.0.name
          #     }
          #   }
          env {
            name  = "BACKEND_SECRET"
            value = "1234"
          }
          env {
            name  = "GITHUB_TOKEN"
            value = var.GITHUB_TOKEN
          }
        }
      }
    }
  }
  depends_on = [
    # null_resource.build,
    azurerm_kubernetes_cluster.landingzone
  ]
}

#  resource "kubernetes_service_v1" "postgres" {
#    metadata {
#      name      = "postgresservice"
#      namespace = kubernetes_namespace_v1.main.metadata.0.name
#    }
#    spec {
#      selector = {
#        app = kubernetes_deployment_v1.postgres.metadata.0.name
#      }
#      port {
#        port = "5432"
#      }
#    }
#    depends_on = [
#      azurerm_kubernetes_cluster.landingzone,
#    ]
#  }


resource "kubernetes_service_v1" "backstage" {
  metadata {
    name      = "backstageservice"
    namespace = kubernetes_namespace_v1.main.metadata.0.name
  }
  spec {
    selector = {
      app = kubernetes_deployment_v1.backstage.metadata.0.name
    }
    port {
      name        = "http"
      port        = "80"
      target_port = "http"
    }
  }
  depends_on = [
    azurerm_kubernetes_cluster.landingzone,
  ]
}

# resource "kubernetes_ingress" "backstage" {
#   metadata {
#     name      = "backstageingress"
#     namespace = kubernetes_namespace_v1.main.metadata.0.name
#     annotations = {
#       "kubernetes.io/ingress.class" = "addon-http-application-routing"
#     }
#   }
#   spec {
#     backend {
#       service_name = kubernetes_service_v1.backstage.metadata.0.name
#       service_port = 80
#     }
#     rule {
#       http {
#         path {
#           path = "/"
#           backend {
#             service_name = kubernetes_service_v1.backstage.metadata.0.name
#             service_port = 80
#           }
#         }
#       }
#     }
#   }
#   depends_on = [
#     azurerm_kubernetes_cluster.landingzone,
#   ]
# }

resource "kubernetes_ingress_v1" "backstage_ingress" {
  metadata {
    name = "backstage-ingress"
  }

  spec {
    default_backend {
      service {
        name = kubernetes_service_v1.backstage.metadata.0.name
        port {
          number = 80
        }
      }
    }

    rule {
      http {
        path {
          backend {
            service {
              name = kubernetes_service_v1.backstage.metadata.0.name
              port {
                number = 80
              }
            }
          }

          path = "/"
        }
      }
    }

    #     tls {
    #       secret_name = "tls-secret"
    #     }
  }

  depends_on = [
    azurerm_kubernetes_cluster.landingzone,
  ]
}