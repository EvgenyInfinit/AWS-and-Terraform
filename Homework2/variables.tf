variable "aws_region" {
  description = "AWS region to deploy all resources"
  type        = string
  default     = "us-east-1"
}

variable "owner_tag" {
  description = "tag applied through the 'default_tags' feature"
  type        = string
  default     = "Evgy"
}

variable "public_subnet_cidrs" {
 type        = list(string)
 description = "Public Subnet CIDR values"
 default     = ["10.0.1.0/24", "10.0.2.0/24"]#, "10.0.3.0/24"]
}
 
variable "private_subnet_cidrs" {
 type        = list(string)
 description = "Private Subnet CIDR values"
 default     = ["10.0.4.0/24", "10.0.5.0/24"]#, "10.0.6.0/24"]
}

variable "azs" {
 type        = list(string)
 description = "Availability Zones"
 default     = ["eu-east-1a", "eu-east-1b"]#, "eu-east-1c"]
}

# variable "azs_number" {
#   description = "Number of availability zones"
#   type        = number
#   default     = 2
# }

variable "ingressrules" {
  type    = list(number)
  default = [80, 443, 22]
}

