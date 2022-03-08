module "instance" {
  source = "../instance"
  instanceSize = var.instanceCapacity
}
resource "aws_s3_bucket" "test" {
  bucket = "name"
}