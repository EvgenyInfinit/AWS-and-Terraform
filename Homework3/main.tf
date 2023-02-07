module "vpc_module" {
    source = "./module"
    vpc_cidr_block = "10.0.0.0/16"
    private_subnets_cidr_list = ["10.0.1.0/24","10.0.2.0/24"]
    public_subnets_cidr_list =["10.0.3.0/24","10.0.4.0/24"]
}

################################################
# aws_instance web
################################################

resource "aws_instance" "web" {
  count                       = var.webs_instances_count
  ami                         = data.aws_ami.Ubuntu.id
  instance_type               = var.instance_type
  key_name                    = var.key_name
  subnet_id                   = module.vpc_module.public_subnets_id[count.index]
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.nginx_allow_http_ssh.id]
  user_data                   = local.user_data

  root_block_device {
    encrypted   = false
    volume_type = var.volumes_type
    volume_size = var.webs_root_disk_size
  }

  ebs_block_device {
    encrypted   = true
    device_name = var.web_encrypted_disk_device_name
    volume_type = var.volumes_type
    volume_size = var.web_encrypted_disk_size
  }
  tags = {
    Name = "nginx-web-${regex(".$", data.aws_availability_zones.available.names[count.index])}"
  }

}

################################################
# aws_instance db
################################################

resource "aws_instance" "DB" {
  count                       = var.DB_instances_count
  ami                         = data.aws_ami.Ubuntu.id
  instance_type               = var.instance_type
  key_name                    = var.key_name
  subnet_id                   = module.vpc_module.private_subnets_id[count.index]
  associate_public_ip_address = false
  vpc_security_group_ids      = [aws_security_group.db_allow_ssh.id]

  tags = {
    Name = "DB-${regex(".$", data.aws_availability_zones.available.names[count.index])}"
  }
}

################################################
# aws_iam_xxx nginx_xxx
################################################

resource "aws_iam_role" "nginx_role" {
  name               = "nginx_role"
  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "sts:AssumeRole"
            ],
            "Principal": {
                "Service": [
                    "ec2.amazonaws.com"
                ]
            }
        }
    ]
})
}

resource "aws_iam_instance_profile" "nginx_instances" {
  name = "s3_access_profile"
  role = aws_iam_role.nginx_role.name
}

resource "aws_iam_role_policy" "nginx_s3_access_policy" {
  name   = "s3_role_policy"
  role   = aws_iam_role.nginx_role.id
  policy = aws_iam_policy.nginx_S3_access.policy
}

resource "aws_iam_policy" "nginx_S3_access" {
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        Effect : "Allow",
        Action : "s3:*",
        Resource : "${aws_s3_bucket.nginx_access_log.arn}/*"
      }
    ]
  })
}


################################################
# aws_lb_xxx web_xxx
################################################

resource "aws_lb" "web_nginx" {
  name               = "nginx-alb-${module.vpc_module.vpc_id}"
  internal           = false
  load_balancer_type = "application"
  subnets            = module.vpc_module.public_subnets_id
  security_groups    = [aws_security_group.nginx_allow_http_ssh.id]

  tags = {
    "Name" = "nginx-alb-${module.vpc_module.vpc_id}"
  }
}

resource "aws_lb_listener" "web_nginx" {
  load_balancer_arn = aws_lb.web_nginx.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_nginx.arn
  }
}

resource "aws_lb_target_group" "web_nginx" {
  name     = "nginx-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = module.vpc_module.vpc_id

  health_check {
    enabled = true
    path    = "/"
  }

  tags = {
    "Name" = "nginx-target-group-${module.vpc_module.vpc_id}"
  }
}

resource "aws_lb_target_group_attachment" "web-server" {
  count            = 2
  target_group_arn = aws_lb_target_group.web_nginx.id
  target_id        = aws_instance.web.*.id[count.index]
  port             = 80
}


################################################
# aws_s3_bucket_xxx nginx_xxx
################################################

resource "aws_s3_bucket" "nginx_access_log" {
  bucket = "nginx-access-log-bucket"

  tags = {
    Name = "nginx-access-log-bucket"
  }
}

resource "aws_s3_bucket_acl" "nginx_bucket_acl" {
    bucket = aws_s3_bucket.nginx_access_log.id
    acl    = "private"
  
}

################################################
# aws_security_group_xxx nginx_xxx db_xxx
################################################

#nginx
resource "aws_security_group" "nginx_allow_http_ssh" {
  name   = "nginx_allow_http_ssh"
  vpc_id = module.vpc_module.vpc_id

  tags = {
    Name = "nginx_allow_http_ssh-${module.vpc_module.vpc_id}"
  }
}

resource "aws_security_group_rule" "nginx_http_access" {
  description       = "Allow HTTP access from anywhere"
  from_port         = 80
  protocol          = "tcp"
  security_group_id = aws_security_group.nginx_allow_http_ssh.id
  to_port           = 80
  type              = "ingress"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "nginx_ssh_access" {
  description       = "Allow SSH access from anywhere"
  from_port         = 22
  protocol          = "tcp"
  security_group_id = aws_security_group.nginx_allow_http_ssh.id
  to_port           = 22
  type              = "ingress"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "nginx_outbound_anywhere" {
  description       = "Allow outbound to anywhere"
  from_port         = 0
  protocol          = "-1"
  security_group_id = aws_security_group.nginx_allow_http_ssh.id
  to_port           = 0
  type              = "egress"
  cidr_blocks       = ["0.0.0.0/0"]
}
#DB
resource "aws_security_group" "db_allow_ssh" {
  name   = "db_allow_ssh"
  vpc_id = module.vpc_module.vpc_id

  tags = {
    Name = "db_allow_http_ssh-${module.vpc_module.vpc_id}"
  }
}

resource "aws_security_group_rule" "db_ssh_access" {
  description       = "Allow SSH access from anywhere"
  from_port         = 22
  protocol          = "tcp"
  security_group_id = aws_security_group.db_allow_ssh.id
  to_port           = 22
  type              = "ingress"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "db_nginx_outbound_anywhere" {
  description       = "Allow outbound to anywhere"
  from_port         = 0
  protocol          = "-1"
  security_group_id = aws_security_group.db_allow_ssh.id
  to_port           = 0
  type              = "egress"
  cidr_blocks       = ["0.0.0.0/0"]
}


