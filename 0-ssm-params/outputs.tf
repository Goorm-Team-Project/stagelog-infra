output "ssm_prefix" {
  value = local.prefix
}

output "parameter_scopes" {
  value = local.parameter_scopes
}

output "string_parameter_count" {
  value = length(local.string_parameters)
}

output "secure_parameter_count" {
  value = length(local.secure_parameters)
}
