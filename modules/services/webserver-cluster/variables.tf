variable "server_port" {
  description = "The port the server will use for HTTP request"
  type        = number
  default     = 8080
}
variable "instance_type" {
  description = "The type of EC2 instances to run"
  type        = string
}

variable "min_size" {
  description = "The minimum number of EC2 instances in the ASG"
  type        = number
}
variable "max_size" {
  description = "The maximum number of EC2 instances in the ASG"
  type        = number
}

variable "cluster_name" {
  description = "The name to use for all the cluster resources"
  type        = string
}

variable "db_remote_state_bucket" {
  description = "The name of the S3 bucket for the database's remote state"
  type        = string
}

variable "db_remote_state_key" {
  description = "The path for the database's remote state in S3"
  type        = string
}

variable "region" {
  description = "The region where ASG will be launching Ec2"
  type        = string
}

variable "custom_tags" {
  description = "Custom tags to set on the Instances in the ASG"
  type        = map(string)
  default     = {}
}

variable "enable_new_user_data" {
  description = "If set to true, use the V2 User Data script"
  type        = bool
}

variable "ami" {
  description = "The AMI to run in the cluster"
  default     = "ami-0c55b159cbfafe1f0"
  type        = string
}

variable "server_text" {
  description = "The text the webserver should return"
  default     = "Hello Terraformers!"
  type        = string
}