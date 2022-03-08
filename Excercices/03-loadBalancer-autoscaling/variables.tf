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

variable "autoscaling_active" {
  type = bool
  default = true
  description = "feature switch for autoscaling"
}

variable "maxNumberOfInstances" {
  type        = number
  default     = 2
  description = "maximum number of webserver instances when autoscaling is active"
}
variable "minNumberOfInstances" {
  type        = number
  default     = 1
  description = "minimum number of webserver instances when autoscaling is active"
}

variable "numberOfInstances" {
  type        = number
  default     = 2
  description = "number of webserver instances when autoscaling is not active"
}