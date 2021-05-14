output "all_arns" {
  value       = aws_iam_user.tfdemouser
  description = "The ARNs for all users"
}

output "upper_names" {
  value = [for name in var.user_names : upper(name)]
}

output "shorter_upper_names" {
  value = [for names in var.user_names : upper(name) if length(name) < 3]
}