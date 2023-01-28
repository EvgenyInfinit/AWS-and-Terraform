output "web_instance_public_ips" {
  value = [aws_instance.web.*.public_ip]
}