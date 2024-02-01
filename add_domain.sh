#!/bin/bash
sudo pkill nginx
# Define variables
DOMAIN=$1

# Check if domain is provided
if [ -z "$DOMAIN" ]; then
    echo "Usage: $0 <domain>"
    exit 1
fi

# Prompt user for the port
read -p "Enter the port for proxy_pass (default is 5173): " PORT
PORT=${PORT:-5173}

# Add NGINX configuration for the new domain
cat <<EOF > /etc/nginx/sites-enabled/$DOMAIN
server {
    server_name $DOMAIN;
    location / {
        proxy_pass http://localhost:$PORT;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
    }
}
EOF

# Create a symbolic link to enable the site
#ln -s /etc/nginx/sites-enabled/$DOMAIN /etc/nginx/sites-available/

# Reload NGINX to apply changes
systemctl stop nginx
systemctl disable nginx
# Run Certbot to obtain SSL certificate
#sudo certbot certonly --standalone -d $DOMAIN
#sudo certbot certonly --nginx --force-renewal --non-interactive -d $DOMAIN
#sudo certbot --nginx -d $DOMAIN
#systemctl restart nginx
#./certbot_expect_script
#./cert_new



# Assuming $DOMAIN contains the new domain name
echo "$(cat /domains.txt),$DOMAIN" | sed 's/^,//' > /domains.txt



./add_ssl.sh
systemctl restart nginx
