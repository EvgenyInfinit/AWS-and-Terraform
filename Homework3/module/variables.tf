variable "vpc_cidr_block" {
  type = string
  description = "The cidr block of the VPC, for ex- '10.0.0.0/16'"
}

variable "private_subnets_cidr_list" {
  type    = list(string)
  description = "List of private subnets of the VOC for ex-['10.0.2.0/24', '10.0.3.0/24']"
}

variable "public_subnets_cidr_list" {
  type    = list(string)
  description = "List of public subnets of the VPC for ex-['10.0.5.0/24', '10.0.6.0/24']"
}

variable "route_tables_name_list" {
  type    = list(string)
  description = "List of the names of the route-tables (Module creates two RTBS, one public [0] and one private [1]"
  default = ["public", "private-a", "private-b"]
}