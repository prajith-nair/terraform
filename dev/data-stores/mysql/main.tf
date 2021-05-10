provider "aws" {
  region = "us-east-2"
}
resource "aws_db_instance" "mysqlstate" {
  instance_class    = "db.t2.micro"
  identifier_prefix = "prajithnairsolutions"
  engine            = "mysql"
  allocated_storage = 10
  name              = "prajithnairmysql"
  username          = "admin"
}