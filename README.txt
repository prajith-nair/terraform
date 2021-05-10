$terraform init 
$terraform plan -var aws_access_key=xxxxx -var aws_secret_key=xxxxx -var region=us-east-2
$terraform apply -var aws_access_key=xxxxx -var aws_secret_key=xxxxx -var region=us-east-2

Note : export environment variable db_password for mysql config
$export TF_VAR_db_password="yourpassword"  
