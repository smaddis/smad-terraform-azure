provider "azurerm" {
    # The "feature" block is required for AzureRM provider 2.x. 
    # If you are using version 1.x, the "features" block is not allowed.
    version = "~>2.0"
    features {}
}

resource "azurerm_resource_group" "k8s_rg" {
    name     = "${lower(var.project_name)}-${var.k8s_resource_group_name_suffix}"
    location = var.location
}

resource "random_id" "log_analytics_workspace_name_suffix" {
    byte_length = 8
}

resource "azurerm_log_analytics_workspace" "log_analytics_ws" {
    # The WorkSpace name has to be unique across the whole of azure, not just the current subscription/tenant.
    name                = "${lower(var.project_name)}-log-analytics-ws-${random_id.log_analytics_workspace_name_suffix.dec}"
    location            = var.log_analytics_workspace_location
    resource_group_name = azurerm_resource_group.k8s_rg.name
    sku                 = var.log_analytics_workspace_sku
}

resource "azurerm_log_analytics_solution" "log_analytics_deployment" {
    solution_name         = "ContainerInsights"
    location              = azurerm_log_analytics_workspace.log_analytics_ws.location
    resource_group_name   = azurerm_resource_group.k8s_rg.name
    workspace_resource_id = azurerm_log_analytics_workspace.log_analytics_ws.id
    workspace_name        = azurerm_log_analytics_workspace.log_analytics_ws.name

    plan {
        publisher = "Microsoft"
        product   = "OMSGallery/ContainerInsights"
    }
}

resource "azurerm_kubernetes_cluster" "k8s_cluster" {
    name                = "${lower(var.project_name)}-${var.k8s_cluster_name_suffix}"
    location            = azurerm_resource_group.k8s_rg.location
    resource_group_name = azurerm_resource_group.k8s_rg.name
    dns_prefix          = var.k8s_dns_prefix

    # Use Managed Identity for K8S cluster identity
    # https://www.chriswoolum.dev/aks-with-managed-identity-and-terraform
    identity {
        type = "SystemAssigned"
    }
    
    # Use Service Principal for K8S cluster identity
    # service_principal {
    #     client_id     = var.client_id
    #     client_secret = var.client_secret
    # }

    # linux_profile {
    #     admin_username = "ubuntu"

    #     ssh_key {
    #         key_data = file(var.k8s_ssh_public_key)
    #     }
    # }

    default_node_pool {
        name            = "agentpool"
        node_count      = var.k8s_agent_count
        vm_size         = "Standard_D2_v2"
    }

    addon_profile {
        oms_agent {
        enabled                    = true
        log_analytics_workspace_id = azurerm_log_analytics_workspace.log_analytics_ws.id
        }
    }

    network_profile {
        load_balancer_sku = "Standard"
        network_plugin = "kubenet"
    }

    tags = {
        environment = var.environment
    }
}
