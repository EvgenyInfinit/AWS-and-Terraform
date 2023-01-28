resource "aws_vpc" "main" {
 cidr_block = "10.0.0.0/16"
 instance_tenancy = "default"
 enable_dns_hostnames = true
 tags = {
   Name = "Evgy-ops9 VPC"
 }
}

resource "aws_subnet" "public_subnets" {
 count      = length(var.public_subnet_cidrs)
 vpc_id     = aws_vpc.main.id
 cidr_block = element(var.public_subnet_cidrs, count.index)
 
 tags = {
   Name = "Public Subnet ${count.index + 1}"
 }
}
 
resource "aws_subnet" "private_subnets" {
 count      = length(var.private_subnet_cidrs)
 vpc_id     = aws_vpc.main.id
 cidr_block = element(var.private_subnet_cidrs, count.index)
 
 tags = {
   Name = "Private Subnet ${count.index + 1}"
 }
}

resource "aws_internet_gateway" "igw" {
 vpc_id = aws_vpc.main.id
 
 tags = {
   Name = "Evgy-ops9-igw"
 }
}

resource "aws_eip" "nat_eip" {
  vpc        = true
}

resource "aws_nat_gateway" "nat" {
  connectivity_type = "public"
  allocation_id     = aws_eip.nat_eip.id
  subnet_id         = aws_subnet.public_subnets.*.id[0]
  tags = {
   Name = "Evgy-ops9-nat"
}

##############

# resource "aws_route_table" "route_table" {
#  vpc_id = aws_vpc.main.id
 
#  route {
#    cidr_block = "0.0.0.0/0"
#    gateway_id = aws_internet_gateway.igw.id
#  }
 
#  tags = {
#    Name = "Route Table"
#  }
 }

# resource "aws_route_table_association" "public_subnet_asso" {
#  count = length(var.public_subnet_cidrs)
#  subnet_id      = element(aws_subnet.public_subnets[*].id, count.index)
#  route_table_id = aws_route_table.route_table.id
# }

#######################

resource "aws_route_table" "public" {
  vpc_id                  = aws_vpc.main.id
}

resource "aws_route" "public" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "public" {
  count          = length(var.public_subnet_cidrs)
  subnet_id      = element(aws_subnet.public_subnets.*.id, count.index)
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  vpc_id                  = aws_vpc.main.id
}

resource "aws_route" "private" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat.id
}

resource "aws_route_table_association" "private" {
  count          = length(var.private_subnet_cidrs)
  subnet_id      = element(aws_subnet.private_subnets.*.id, count.index)
  route_table_id = aws_route_table.private.id
}
