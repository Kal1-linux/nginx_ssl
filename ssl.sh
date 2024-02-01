#!/bin/bash

NGINX_CONF_DIR=$1
CERTBOT_BIN="/usr/bin/certbot"  # Update this path if necessary
DEFAULT_DOMAIN="server.qwiksavings.com"
CERT_ISSUED_DOMAIN_LIST="/root/letsencrypt/cert_issued_domains"
ISSUED_CERT_PATH="/etc/letsencrypt/live/$DEFAULT_DOMAIN"
ISSUED_RENEWAL_CONF="/etc/letsencrypt/renewal/"
ISSUED_CERT_ARCHIVE="/etc/letsencrypt/archive"

issue_new_crt() {

    NEW_CRT_CMD=$CERTBOT_BIN" certonly --standalone -d "$DEFAULT_DOMAIN
    RENEW_CRT_CMD=$CERTBOT_BIN" renew --force-renew"
    DOMAIN_LIST=""
    ISSUE_NEW_CRT=false
    
    echo 
    echo 
    echo "Certificate will be issued for domain(s) listed below"
    echo "------------------------------------------------------"

    # Add a new NGINX configuration file for server.qwiksavings.com
    NGINX_CONF_FILE="$NGINX_CONF_DIR/server.qwiksavings.com"
    cat <<EOF > "$NGINX_CONF_FILE"
server {
    listen 80;
    server_name server.qwiksavings.com;
    return 301 https://\$host\$request_uri;
}

server {
    listen 443 ssl;
    server_name server.qwiksavings.com;

    # SSL configuration (add other settings as needed)
    ssl_certificate $ISSUED_CERT_PATHfull/chain.pem;
    ssl_certificate_key $ISSUED_CERT_PATH/privkey.pem;

    location / {
        proxy_pass http://localhost:5173;
        # ... (other proxy settings)
    }
}
EOF

    for entry in "$NGINX_CONF_DIR"/ssl-*
    do
      if [ -f "$entry" ];then
          TEMP_DOMAIN_NAME=$(basename "$entry" | sed "s/ssl-//")
          DOMAIN_NAME=$(echo "$TEMP_DOMAIN_NAME")
          DOMAIN_LIST=$DOMAIN_LIST$DOMAIN_NAME" "
          NEW_CRT_CMD=$NEW_CRT_CMD" -d "$DOMAIN_NAME
          #Check if certificate is already issued or not
          grep -wr "$DOMAIN_NAME" "$CERT_ISSUED_DOMAIN_LIST" > /dev/null
     	  if [ $? -eq 0 ] ; then
		echo "$DOMAIN_NAME"
	  else
		echo "$DOMAIN_NAME  ---NEW---"
		ISSUE_NEW_CRT=true
	  fi     
      fi
    done
    NEW_CRT_CMD=$NEW_CRT_CMD" --force-renew"
    echo "------------------------------------------------------"

    if [ "$ISSUE_NEW_CRT" = true ]; then
       rm -rf "$ISSUED_CERT_PATH" #remove old certificates 
       rm -rf "$ISSUED_RENEWAL_CONF" #remove old certificate configuration
       rm -rf "$ISSUED_CERT_ARCHIVE" #remove archive certificate configuration
       $NEW_CRT_CMD
       if [ $? -eq 0 ] ; then #if certs issued successfully
           echo "$DOMAIN_LIST" > "$CERT_ISSUED_DOMAIN_LIST"
       fi
    else
	$RENEW_CRT_CMD
    fi
}

# Execute the function with the NGINX configuration directory
issue_new_crt "$NGINX_CONF_DIR"

