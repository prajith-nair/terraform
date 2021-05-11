output "address" {
  value       = aws_db_instance.mysqlstate.address
  description = "Connect to database at this endpoint"
}

output "port" {
  value       = aws_db_instance.mysqlstate.port
  description = "The port the database is listening on"
}
