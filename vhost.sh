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

# Prompt for the domain name
read -p "Enter the domain name (e.g., yourdomain.com): " domain

# Prompt for ServerAlias
read -p "Do you want to add an alias domain? (y/n): " add_alias

if [[ $add_alias == "y" || $add_alias == "Y" || $add_alias == "Yes" || $add_alias == "YES" || $add_alias == "yes" ]]; then
    read -p "Enter the alias domain (e.g., www.$domain): " alias_domain
    alias_domain="ServerAlias $alias_domain"
    ssl="sudo certbot --apache -d $domain -d $alias_domain"
else
    alias_domain=""
    ssl="sudo certbot --apache -d $domain"
fi

# Get DocumentRoot and ServerRoot
DocumentRoot=$(apachectl -t -D DUMP_RUN_CFG | grep DocumentRoot | awk '{print $3}')
ServerRoot=$(apachectl -t -D DUMP_RUN_CFG | grep ServerRoot | awk '{print $2}')

ServerRoot="${ServerRoot//\"/}"
DocumentRoot="${DocumentRoot//\"/}"
DocumentRoot="$DocumentRoot/$domain"

# Confirm DocumentRoot and ServerRoot
echo "Your Website root Directory will be $DocumentRoot/public_html"

read -p "Do you want to modify root Directory? (y/n): " rootDirectory

if [[ $rootDirectory == "y" || $rootDirectory == "Y" || $rootDirectory == "Yes" || $rootDirectory == "YES" || $rootDirectory == "yes" ]]; then
    read -p "Enter new Website root Directory (e.g., $DocumentRoot/public_html): " DocumentRoot
    echo "Your Website root Directory will be $DocumentRoot"
else
    echo "Thank you for confirmation :)"
    echo "Your Website root Directory will be $DocumentRoot/public_html"
fi

# Create the directory structure with the provided domain
echo "Creating the directory structure virtual host..."
sudo mkdir -p $DocumentRoot/{backups,logs,public_html}

# Set Permissions
echo "Setting Permissions for virtual host..."
sudo chown -R $USER:$USER $DocumentRoot/public_html
sudo chmod -R 755 $DocumentRoot
sudo chown -R www-data:www-data $DocumentRoot

# Insert the Apache configuration into the file
echo "Configuring Apache server..."
cat <<EOL | sudo tee -a $ServerRoot/sites-available/$domain.conf > /dev/null
<VirtualHost *:80>
    ServerAdmin webmaster@$domain
    ServerName $domain
    $alias_domain
    DocumentRoot $DocumentRoot/public_html

    <Directory $DocumentRoot/public_html>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog $DocumentRoot/logs/error.log
    CustomLog $DocumentRoot/logs/access.log combined
</VirtualHost>
EOL

# Enable the Virtual Host
echo "Enabling the Virtual Host..."
sudo a2ensite $domain.conf > /dev/null

# Restart Apache to apply changes
echo "Restarting Apache server..."
sudo systemctl restart apache2 > /dev/null

# Display confirmation message based on Certbot installation
echo "Congratulations, your new website is ready to use!"
echo "Checking SSL status..."
if [ "$certbot_installed" == "true" ]; then
    echo "Run the following command to install SSL if Certbot is installed:"
    echo "$ssl"
else
    echo "Certbot is not installed. You'll need to install it to enable SSL for your website."
fi
