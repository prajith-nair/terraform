output "all_arns" {
  value = aws_iam_user.tfdemouser[*].arn
  description = "The ARNs for all users"
}