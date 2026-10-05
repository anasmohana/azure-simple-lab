output "oidc_issuer_url" {
  value = try(module.aks["main"].oidc_issuer_url, null)
}
