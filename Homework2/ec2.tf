##################################################################################
# security
##################################################################################
resource "aws_security_group" "web_traffic" {
  name        = "Allow web traffic"
  description = "Allow ssh and standard http/https ports inbound and everything outbound"
  vpc_id     = aws_vpc.main.id
  dynamic "ingress" {
    iterator = port
    for_each = var.ingressrules
    content {
      from_port   = port.value
      to_port     = port.value
      protocol    = "TCP"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
  
    egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
    tags = {
    "Terraform" = "true"
  }
}
##################################################################################
# key
##################################################################################
resource "tls_private_key" "demo_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "aws_key_pair" "demo_key" {
  key_name   = "demo"
  public_key = tls_private_key.demo_key.public_key_openssh
}
# Save generated key pair locally
  resource "local_file" "server_key" {
  sensitive_content  = tls_private_key.demo_key.private_key_pem
  filename           = "private.pem"
}

##################################################################################
# instance web + db
##################################################################################

resource "aws_instance" "web" {
  count                        = 2
  ami                          = data.aws_ami.ubuntu.id #"ami-0b5eea76982371e91" # us-east-1
  instance_type                = "t3.micro"
  subnet_id                    = element(aws_subnet.public_subnets.*.id, count.index)
  associate_public_ip_address  = true
  #security_groups              = [aws_security_group.web_traffic.name]
  vpc_security_group_ids       = [aws_security_group.web_traffic.id]
  user_data                    = local.web_user_data
  key_name                     = "${aws_key_pair.demo_key.key_name}"
  tags                         = {
    Name = "Web_Server_${count.index}"
    Purpose    = "web server"
    #Owner      = "Evgy"
  }
  # root disk
  root_block_device {
    volume_size           = "10"
    volume_type           = "gp2"
  #  encrypted             = true
    delete_on_termination = true
  } 
  
  # data disk  
  ebs_block_device {
    device_name           = "/dev/sdb"
    volume_size           = 10
    volume_type           = "gp2"
    encrypted             = true
  }
 } 
 
 
 resource "aws_instance" "db" {
  count                        = 2
  ami                          = data.aws_ami.ubuntu.id 
  instance_type                = "t3.micro"
  subnet_id                    = element(aws_subnet.private_subnets.*.id, count.index)
  associate_public_ip_address  = false
  #security_groups              = [aws_security_group.web_traffic.name]
  vpc_security_group_ids       = [aws_security_group.web_traffic.id]
  key_name                     = "${aws_key_pair.demo_key.key_name}"
  tags                         = {
                                  Name = "DB_Server_${count.index}"
                                  Purpose    = "db server"
  }
  
  # root disk
  root_block_device {
    volume_size                = 10
    volume_type                = "gp2"
    delete_on_termination      = true
  } 
  
 # data disk  
 ebs_block_device {
    device_name           = "/dev/sdb"
    volume_size           = 10
    volume_type           = "gp2"
    encrypted             = true
  } 
}

##################################################################################
# elb
##################################################################################
resource "aws_elb" "elb" {
  name                        = "whiskey-elb"
  subnets                     = aws_subnet.public_subnets.*.id
  instances                   = aws_instance.web.*.id
  security_groups             = [aws_security_group.web_traffic.id]
  cross_zone_load_balancing   = true
  idle_timeout                = 120
  connection_draining         = true
  connection_draining_timeout = 300

  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  health_check {
    healthy_threshold   = 5
    unhealthy_threshold = 3
    target              = "HTTP:80/"
    interval            = 30
    timeout             = 5
  }
}
