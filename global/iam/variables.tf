variable "user_names" {
  description = "Create IAM users with these names"
  type        = list(string)
  default     = ["hulk", "ironman", "thor"]
}

variable "give_thor_cloudwatch_full_access" {
  description = "If true, thor gets full access to cloudwatch"
  type        = bool
}

