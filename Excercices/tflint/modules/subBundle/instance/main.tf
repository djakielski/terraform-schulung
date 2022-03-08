resource "aws_instance" "test" {
  ami = "151351df"
  instance_type = var.instanceBundleType
}