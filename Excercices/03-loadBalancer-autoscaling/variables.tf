variable "project" {
  type        = string
  description = "Name of the project"
}

variable "instance_type" {
  type        = string
  default     = "t3.nano"
  description = "Type of the EC2 Instance for TF Training."
}

variable "port" {
  type        = number
  default     = 80
  description = "Port of the webserver"
}