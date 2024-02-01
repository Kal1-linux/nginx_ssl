#!/usr/bin/expect -f

# Set timeout
set timeout 30

# Run Certbot command
spawn sudo certbot certonly --standalone -d rahul5.qwiksavings.com

# Expect Certbot prompts
expect "Enter email address (used for urgent renewal and security notices) (Enter 'c' to cancel):"
send "\r"  # Press Enter to skip entering email

expect "Agree to the terms of service (required)"
send "2\r"  # Choose the 2nd option

expect eof

