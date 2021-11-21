output "dns_name" {
  value       = aws_lb.webserver.dns_name
  description = "public dns name of our webserver"
}