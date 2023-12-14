variable "instance_count" {
  description = "Number of EC2 instances to create"
  default     = 3
}

variable "security_group_id" {
  description = "ID of the security group for EC2 instances"
  
}

variable "subnet_id" {
  description = "ID of the subnet for EC2 instances"
  
}

variable "key" {
  description = "Name of the SSH key pair for EC2 instances"
  
}

variable "name" {
  description = "Name prefix for EC2 instances"
  
}

variable "default_ec2_tags" {
  type        = map(string)
  description = "(optional) default tags for EC2 instances"
  default = {
    managed_by   = "terraform"
    Environment  = "Dev"
  }
}

variable "AWS_ACCESS_KEY_ID" {
  description = "Aws Access key id"

}

variable "AWS_SECRET_ACCESS_KEY" {
  description = "Secret access key"

}
