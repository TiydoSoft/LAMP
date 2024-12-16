#!/bin/bash

set -e

# Ensure script is run as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root"
    exit 1
fi

# Prompt for MySQL root password securely
read -sp "Enter new password for MySQL: " mysql_pwd
echo

# Function to check if a package is installed
is_installed() {
    dpkg -l | grep -q "^ii  $1 "
}

# Install Apache
if ! is_installed apache2; then
    echo "Installing Apache..."
    sudo apt update && sudo apt install apache2 -y
    sudo systemctl enable --now apache2
    echo "Apache installation completed."
else
    echo "Apache is already installed."
fi

# Install MySQL
if ! is_installed mysql-server; then
    echo "Installing MySQL..."
    sudo apt install -y mysql-server
    sudo systemctl enable --now mysql
    echo "MySQL installation completed."
else
    echo "MySQL is already installed."
fi

# Configure MySQL root user and secure installation
echo "Configuring MySQL..."
sudo mysql <<EOF
ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '$mysql_pwd';
DELETE FROM mysql.user WHERE User='';
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
FLUSH PRIVILEGES;
EOF

echo "MySQL root password set and basic security measures applied."

# Install PHP
if ! is_installed php; then
    echo "Installing PHP..."
    sudo apt install php libapache2-mod-php php-mysql php-curl php-gd php-mbstring php-xml php-xmlrpc php-soap php-intl php-zip php-imagick -y
    sudo systemctl restart apache2
    echo "PHP installation completed."
else
    echo "PHP is already installed."
fi

# Install phpMyAdmin
if ! is_installed phpmyadmin; then
    echo "Installing phpMyAdmin..."
    sudo apt install phpmyadmin -y

    # Configure phpMyAdmin to work with Apache
    sudo ln -s /usr/share/phpmyadmin /var/www/html/phpmyadmin || true
    sudo systemctl reload apache2
    echo "phpMyAdmin installation completed."
else
    echo "phpMyAdmin is already installed."
fi

# Install Certbot
if ! is_installed certbot; then
    echo "Installing Certbot for SSL..."
    sudo apt install -y certbot python3-certbot-apache
    echo "Certbot installation completed."
else
    echo "Certbot is already installed."
fi

# Add a cron job for automatic certificate renewal
if ! crontab -l | grep -q "certbot renew"; then
    echo "Adding cron job for SSL certificate renewal..."
    (crontab -l 2>/dev/null; echo "0 3 * * * certbot renew --quiet && systemctl reload apache2") | crontab -
    echo "Cron job added."
else
    echo "Cron job for SSL certificate renewal already exists."
fi

# Display completion message
echo "LAMP stack installation with Certbot completed successfully."
SERVER_IP=$(hostname -I | awk '{print $1}')
echo "You can access phpMyAdmin at: http://$SERVER_IP/phpmyadmin/"
