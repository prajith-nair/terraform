provider "aws" {
  profile = "prajithnairsolutions"
  region  = "us-east-2"
}

module "webserver_cluster" {
  source                 = "../../../modules/services/webserver-cluster"
  cluster_name           = "webserver-prod"
  db_remote_state_bucket = "tf-prajith-bucket"
  db_remote_state_key    = "prod/data-store/mysql/terraform.tfstate"
  instance_type          = "m4.large"
  min_size               = 2
  max_size               = 3
  aws_access_key         = ""
  aws_secret_key         = ""
  region                 = "us-east-2"
}

#Increase the number of servers to 2 during morning 9 am everyday
resource "aws_autoscaling_schedule" "scale_out_during_business_hours" {
  scheduled_action_name  = "scale-out-during-business-hours"
  min_size               = 1
  max_size               = 2
  desired_capacity       = 2
  recurrence             = "0 9 * * *"
  autoscaling_group_name = module.webserver_cluster.asg_name
}

#Decrease the number of servers to 2 at 5pm everyday

resource "aws_autoscaling_schedule" "scale_in_at_night" {
  scheduled_action_name  = "scale_in_at_night"
  min_size               = 1
  max_size               = 2
  desired_capacity       = 2
  recurrence             = "0 17 * * *"
  autoscaling_group_name = module.webserver_cluster.asg_name
}



