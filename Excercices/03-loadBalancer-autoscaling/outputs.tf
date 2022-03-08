output "dns_name" {
  value       = aws_lb.webserver.dns_name
  description = "public dns name of our webserver"
}

output "url" {
  value       = "http://${aws_lb.webserver.dns_name}:${var.port}"
  description = "url of our webserver including port"
}