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
