locals {
/*
user_data = <<EOF
#!bin/bash
sudo apt install nginx -y
#sudo amazon-linux-extras install nginx1 -y
sudo systemctl start nginx
#sudo service nginx start
#sudo service nginx enable
echo "Welcome to Grandpa's Whiskey" | sudo tee /var/www/html/index.nginx-debian.html
EOF
*/
web_user_data = <<EOF
#!/bin/bash
sudo apt update -y
sudo apt install nginx -y
sed -i "s/nginx/Grandpa's Whiskey/g" /var/www/html/index.nginx-debian.html
sed -i '15,23d' /var/www/html/index.nginx-debian.html
service nginx restart
EOF
}