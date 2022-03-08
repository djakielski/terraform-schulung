provider "aws" {
  region = "eu-central-1"
}

module "workingBundle" {
  source = "./modules/bundle"
  instanceCapacity = var.instanceType
}

module "workingInstance" {
  source = "./modules/instance"
  instanceSize = var.instanceType
}

module "nonWorkingSubBundle" {
  source = "./modules/subBundle"
  instanceSubBundleType = var.instanceType
}