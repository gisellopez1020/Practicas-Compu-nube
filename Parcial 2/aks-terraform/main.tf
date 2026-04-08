terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# RESOURCE GROUP
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

# AKS CLUSTER
resource "azurerm_kubernetes_cluster" "aks" {
  name                = var.cluster_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = var.cluster_name

  default_node_pool {
    name       = "default"
    node_count = 1
    vm_size    = "Standard_D2s_v3"
  }

  identity {
    type = "SystemAssigned"
  }

  tags = {
    environment = "parcial"
  }
}

# PROVIDER KUBERNETES
provider "kubernetes" {
  host                   = azurerm_kubernetes_cluster.aks.kube_config[0].host
  client_certificate     = base64decode(azurerm_kubernetes_cluster.aks.kube_config[0].client_certificate)
  client_key             = base64decode(azurerm_kubernetes_cluster.aks.kube_config[0].client_key)
  cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.aks.kube_config[0].cluster_ca_certificate)
}

# NAMESPACE
resource "kubernetes_namespace" "microapp" {
  depends_on = [azurerm_kubernetes_cluster.aks]
  metadata {
    name = "microapp"
  }
}

locals {
  services = {
    users = {
      image    = "gisel2106/users-service:latest"
      port     = 5002
      svc_port = 3001
    }
    products = {
      image    = "gisel2106/products-service:latest"
      port     = 5003
      svc_port = 3002
    }
    orders = {
      image    = "gisel2106/orders-service:latest"
      port     = 5004
      svc_port = 3003
    }
  }
}

# DEPLOYMENTS
resource "kubernetes_deployment" "microservices" {
  for_each   = local.services
  depends_on = [kubernetes_namespace.microapp]

  metadata {
    name      = "${each.key}-deployment"
    namespace = "microapp"
  }

  spec {
    replicas = 2

    selector {
      match_labels = {
        app = "${each.key}-service"
      }
    }

    template {
      metadata {
        labels = {
          app = "${each.key}-service"
        }
      }

      spec {
        container {
          name  = "${each.key}-service"
          image = each.value.image

          port {
            container_port = each.value.port
          }

          env {
            name  = "FLASK_APP"
            value = "run.py"
          }
          env {
            name  = "FLASK_ENV"
            value = "production"
          }
          env {
            name  = "MYSQL_HOST"
            value = "mysql"
          }
          env {
            name  = "MYSQL_PORT"
            value = "3306"
          }
          env {
            name  = "MYSQL_DATABASE"
            value = "myflaskapp"
          }
          env {
            name  = "MYSQL_USER"
            value = "root"
          }
          env {
            name  = "MYSQL_ROOT_PASSWORD"
            value = "root"
          }

          resources {
            requests = {
              memory = "128Mi"
              cpu    = "100m"
            }
            limits = {
              memory = "256Mi"
              cpu    = "200m"
            }
          }
        }
      }
    }
  }
}

# SERVICES (ClusterIP)
resource "kubernetes_service" "microservices" {
  for_each   = local.services
  depends_on = [kubernetes_namespace.microapp]

  metadata {
    name      = "${each.key}-svc"
    namespace = "microapp"
  }

  spec {
    selector = {
      app = "${each.key}-service"
    }

    port {
      port        = each.value.svc_port
      target_port = each.value.port
    }

    type = "ClusterIP"
  }
}
