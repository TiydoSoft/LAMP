#!/bin/bash

# Function to colorize text
colorize() {
    echo -e "\e[32m$1\e[0m"  # 32 represents green color
}

# Calculate the width of the terminal
columns=$(tput cols)

# The ASCII art to display
art="
@@@@@@@@@@@@@@@@@@+@@@@@@
@@@@@@@@@@@@@@:::....:@@@
@@@@@@@@@@@@@:::::.....@@
@@@@@@@@@@@@---::::....@@
@@@@@@@@@-=---@@@@@@@...@
@@@@@@@++=====-----:::::@
@@@@@@+++======-----::::@
@@@@@+++@@=+=@@@@@@:-- @@
@@@@@++@@@++@@+===@@@@@@@
@@@@@*+@@@++@@=+==@@@@@@@
@@@@@**@@@++@@++++@@@@@@@
@@@@@**+@+++@@++=++@@@@@@
@@@@@@**@+*=@=++@++@@@@@@
@@@@@@**=**@@+++@=++@@@@@
@@@@@@@****@@**@@@++@@@@@
@@@@@@@***=@@**@@@++@@@@@
@@@@@@@****@@**@@@*+@@@@@
@@=*+=@@@@@@**+@@**+@@@@@
@*************+****@@@@@@
@***+*************@@@@@@@
@**=@@@@@@@***==@@@@@@@@@
@@*******+***@@@@@@@@@@@@
@@++********@@@@@@@@@@@@@
@@@.******+@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@

Welcome to TiydoSoft(TiydoSoft.tech)!
"

# Calculate the number of lines in the ASCII art
lines=$(echo "$art" | wc -l)

# Calculate the vertical padding (half of the remaining lines)
vertical_padding=$(( (columns - lines) / 2 ))

# Center the ASCII art both horizontally and vertically and colorize it
while read -r line; do
    # Calculate the horizontal padding for each line
    horizontal_padding=$(( (columns - ${#line}) / 2 ))
    
    # Add the horizontal and vertical padding, then print the colorized line
    printf "%*s%s\n" $horizontal_padding "" "$(colorize "$line")"
done <<< "$art"



read -p "Enter new password for mysql (e.g., 12345): " myqsl_pwd


# Install Apache
echo "Installing Apache....."
sudo apt install apache2 -y
# Enable Apache to start on boot
sudo systemctl enable apache2
# Start Apache
sudo systemctl start apache2
echo "Apache installation completed."
sleep 2



# Install MariaDB and secure installation
echo "Installing MariaDB....."
sudo apt install -y mariadb-server mariadb-client

# # Secure MariaDB installation and set root password
sudo mysql_secure_installation <<EOF

y
$myqsl_pwd
$myqsl_pwd
y
y
y
y
EOF




echo "MariaDB installation and configuration completed."
sleep 2



# Install PHP
echo "Installing PHP......"
sudo apt install php libapache2-mod-php php-mysql php-curl php-gd php-mbstring php-xml php-xmlrpc php-soap php-intl php-zip php-imagick -y

# Restart Apache to load PHP
sudo systemctl restart apache2
echo "PHP installation completed."
sleep 2



# Install phpMyAdmin
echo "Installing phpMyAdmin......"
sudo apt install phpmyadmin -y

# Configure phpMyAdmin to work with Apache
sudo ln -s /etc/phpmyadmin/apache.conf /etc/apache2/sites-available/phpmyadmin.conf
sudo a2ensite phpmyadmin.conf

# Reload Apache to apply changes
sudo systemctl reload apache2
echo "phpMyAdmin installation completed."
sleep 2


# /****/
sudo mysql <<EOF
ALTER USER 'root'@'localhost' IDENTIFIED BY '$myqsl_pwd';
GRANT ALL PRIVILEGES ON *.* TO 'root'@'localhost' WITH GRANT OPTION;
FLUSH PRIVILEGES;
EOF
# /****/


# Display completion message
echo "LAMP stack with phpMyAdmin is installed and configured successfully."
SERVER_IP=$(hostname -I | awk '{print $1}')
echo "Access phpMyAdmin at http://$SERVER_IP/phpmyadmin/"