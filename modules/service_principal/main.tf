# Createa a service principal with random password.

resource "random_string" "password" {
 length = 24
 special = true
}

resource "azurerm_azuread_service_principal" "test" {
  application_id = "${azurerm_azuread_application.test.application_id}"
}

resource "azurerm_azuread_service_principal_password" "test" {
  service_principal_id = "${azurerm_azuread_service_principal.test.id}"
  value                = "${sha256(bcrypt(random_string.password.result))}"
  end_date             = "2021-01-01T01:02:03Z"
  lifecycle {
    ignore_changes = ["plaintext_password"]
  }
}
