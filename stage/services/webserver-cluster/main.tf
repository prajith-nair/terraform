provider "aws" {
  profile = "prajithnairsolutions"
  region = "us-east-2"
}

module "webserver_cluster" {
  source                 = "../../../modules/services/webserver-cluster"
  cluster_name           = "webserver-stage"
  db_remote_state_bucket = "tf-prajith-bucket"
  db_remote_state_key    = "stage/data-store/mysql/terraform.tfstate"
  instance_type          = "t2.micro"
  min_size               = 2
  max_size               = 2
  aws_access_key = ""
  aws_secret_key = ""
  region = "us-east-2"
}

resource "aws_security_group_rule" "allow_testing_inbound" {
  from_port         = 9001
  protocol          = "tcp"
  security_group_id = module.webserver_cluster.alb_security_group_id
  to_port           = 9001
  type              = "ingress"
  cidr_blocks       = ["0.0.0.0/0"]
}

