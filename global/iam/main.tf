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
resource "aws_iam_policy" "cloudwatch_read_only" {
  name   = "cloudwatch_read_only"
  policy = data.aws_iam_policy_document.cloudwatch_read_only.json
}

data "aws_iam_policy_document" "cloudwatch_read_only" {
  statement {
    effect = "Allow"
    actions = [
      "cloudwatch:Describe*",
      "cloudwatch:Get*",
      "cloudwatch:List*"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "cloudwatch_full_access" {
  name   = "cloudwatch_full_access"
  policy = data.aws_iam_policy_document.cloudwatch_full_access.json
}

data "aws_iam_policy_document" "cloudwatch_full_access" {
  statement {
    effect    = "Allow"
    actions   = ["cloudwatch:*"]
    resources = ["*"]
  }
}
