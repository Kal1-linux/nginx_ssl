#!/bin/bash

# Script to automate SSL certificate issuance, NGINX configuration, and enabling site using acme.sh with DNS verification

# Prompt user for email, port, domain, DNS provider, and NGINX config file name
read -p "Enter your email address for registration with acme.sh: " email
read -p "Enter the port for the NGINX server: " port
read -p "Enter the domain for the NGINX server: " domain
read -p "Enter your DNS provider (e.g., dns_cf, dns_aws): " dns_provider
read -p "Enter the NGINX config file name (e.g., my_domain): " nginx_config_name

# Install acme.sh if not already installed
if [ ! -d ~/.acme.sh ]; then
    echo "Installing acme.sh..."
    curl https://get.acme.sh | sh
fi

# Register account with acme.sh
~/.acme.sh/acme.sh --register-account -m $email

# Issue SSL certificate with DNS verification
~/.acme.sh/acme.sh --issue -d $domain --dns $dns_provider

# Update NGINX configuration
nginx_config_path="/etc/nginx/sites-available/$nginx_config_name"
cat <<EOF > $nginx_config_path
server {
    server_name $domain;
    location / {
        proxy_pass http://localhost:$port;
        # ... (other proxy settings)
    }

    listen 443 ssl; # managed by acme.sh
    ssl_certificate ~/.acme.sh/$domain/fullchain.cer;
    ssl_certificate_key ~/.acme.sh/$domain/$domain.key;

    # ... (other SSL-related settings)

    # Redirect HTTP to HTTPS
    if (\$scheme != "https") {
        return 301 https://\$host\$request_uri;
    }
}

server {
    server_name $domain;
    listen 80;
    return 404; # or redirect to HTTPS
}
EOF

# Create a symbolic link in sites-enabled folder
sudo ln -s $nginx_config_path /etc/nginx/sites-enabled/

# Reload NGINX
sudo systemctl reload nginx

echo "SSL certificate for $domain has been obtained, NGINX configuration updated, and site enabled."

