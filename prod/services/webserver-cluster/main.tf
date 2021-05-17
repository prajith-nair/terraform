provider "aws" {
  profile = "prajithnairsolutions"
  region  = "us-east-2"
}

module "webserver_cluster" {
  source                 = "../../../modules/services/webserver-cluster"
  cluster_name           = "webserver-prod"
  db_remote_state_bucket = "tf-prajith-bucket"
  db_remote_state_key    = "prod/data-store/mysql/terraform.tfstate"

  instance_type  = "t2.medium"
  min_size       = 2
  max_size       = 4
  aws_access_key = ""
  aws_secret_key = ""
  region         = "us-east-2"

  enable_autoscaling   = true

  custom_tags = {
    Owner      = "prajith"
    DeployedBy = "terraform"
  }
}


