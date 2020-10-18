provider "azurerm" {
    # The "feature" block is required for AzureRM provider 2.x. 
    # If you are using version 1.x, the "features" block is not allowed.
    version = "~>2.0"
    features {}
}

# module "tfstate_storage_azure" {
#     source  = "./modules/tfstate_storage_azure"
#
#     location = "West Europe"
#     project_name = "kuksatrng"
#     environment = "development"
#     tfstate_storage_account_name_suffix = "tfstatesa"
# }

module "k8s_cluster_azure" {
    source = "./modules/k8s"

    k8s_agent_count = var.k8s_agent_count
}

module "container_registry_for_k8s" {
    source = "./modules/container_registry"

    k8s_cluster_node_resource_group = module.k8s_cluster_azure.k8s_cluster_node_resource_group
    k8s_cluster_kubelet_managed_identity_id = module.k8s_cluster_azure.kubelet_object_id
}

module "keyvault_for_secrets" {
    source = "./modules/keyvault"

    policies = {
        # full_permission = {
        #   tenant_id               = var.azure-tenant-id
        #   object_id               = var.kv-full-object-id
        #   key_permissions         = var.kv-key-permissions-full
        #   secret_permissions      = var.kv-secret-permissions-full
        #   certificate_permissions = var.kv-certificate-permissions-full
        #   storage_permissions     = var.kv-storage-permissions-full
        # }
        read_policy_for_k8s_kubelet = {
        tenant_id               = module.k8s_cluster_azure.mi_tenant_id
        object_id               = module.k8s_cluster_azure.kubelet_object_id
        key_permissions         = var.kv-key-permissions-read
        secret_permissions      = var.kv-secret-permissions-read
        certificate_permissions = var.kv-certificate-permissions-read
        storage_permissions     = var.kv-storage-permissions-read
        }
    }

}

module "k8s_csi_driver_azure"{
    source = "./modules/k8s_csi_driver_azure"

    k8s_host = module.k8s_cluster_azure.host
    k8s_username = module.k8s_cluster_azure.cluster_username
    k8s_password = module.k8s_cluster_azure.cluster_password
    k8s_client_cert = module.k8s_cluster_azure.client_certificate
    k8s_client_key = module.k8s_cluster_azure.client_key
    k8s_cluster_ca_cert = module.k8s_cluster_azure.cluster_ca_certificate

}

terraform {
    backend "azurerm" {
        # Shared state is stored in Azure
        # (https://www.terraform.io/docs/backends/types/azurerm.html)
        #
        # Use './modules/tfstate_storage_azure/main.tf' to create one if needed.
        # See README.md for more details.
        #
        # Authentication is expected to be done via Azure CLI
        # For other authentication means see documentation provided by Microsoft:
        # https://docs.microsoft.com/en-us/azure/developer/terraform/store-state-in-azure-storage
        #
        # Set to "${lower(var.project_name)}-${var.tfstate_resource_group_name_suffix}"
        resource_group_name  = "kuksatrng-tfstate-rg"
        # Set to "${lower(var.project_name)}${var.tfstate_storage_account_name_suffix}"
        storage_account_name = "kuksatrngtfstatesa"
        # Set to var.tfstate_container_name
        container_name       = "tfstate"
        # Set up "${lower(var.project_name)}.tfstate"
        key                  = "kuksatrng.tfstate"
    }
}
