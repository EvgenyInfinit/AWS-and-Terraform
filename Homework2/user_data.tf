locals {
web_user_data = <<EOF
#!/bin/bash
sudo apt update -y
sudo apt install nginx -y
##sed -i "s/nginx/Grandpa's Whiskey/g" /var/www/html/index.nginx-debian.html
##sed -i '15,23d' /var/www/html/index.nginx-debian.html
echo "Welcome to Grandpa's Whiskey" | sudo tee /var/www/html/index.nginx-debian.html
service nginx restart
EOF
}