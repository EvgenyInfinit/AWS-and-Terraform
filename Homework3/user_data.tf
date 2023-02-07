locals {

  user_data = <<-EOF
#! /bin/bash

sudo apt update -y
sudo apt install nginx -y
sed -i "s/nginx/Grandpa's Whiskey/g" /var/www/html/index.nginx-debian.html
sed -i '15,23d' /var/www/html/index.nginx-debian.html
service nginx restart
# Change Nginx configuration to get real user’s IP address in Nginx log files-
echo "set_real_ip_from  ${module.vpc_module.vpc_cidr};" >> /etc/nginx/conf.d/default.conf; echo "real_ip_header    X-Forwarded-For;" >> /etc/nginx/conf.d/default.conf
service nginx restart
# Upload web server access logs to S3 every hour-
echo "0 * * * * aws s3 cp /var/log/nginx/access.log s3://nginx-access-log-bucket" > /var/spool/cron/crontabs/root
EOF
}