variable "aws_access_key" {}
variable "aws_secret_key" {}

provider "aws" {
  profile = "prajithnairsolutions"
  region  = "us-east-2"
}
resource "aws_iam_user" "tfdemouser" {
  for_each = toset(var.user_names)
  name     = each.value
  #count = length(var.user_names)
  #name = var.user_names[count.index]
}