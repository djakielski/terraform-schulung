output "public_ip" {
  value       = aws_instance.webserver.public_ip
  description = "public IP address of our webserver"
}

output "dns_name" {
  value       = aws_instance.webserver.public_dns
  description = "public dns name of our webserver"
}