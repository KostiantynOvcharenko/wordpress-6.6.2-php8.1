#! /usr/bin/env bash

# Variables
APPENV=local
DBHOST=localhost
DBNAME=wordpress
DBUSER=wordpress
DBPASSWD=wordpress

echo -e "\n--- Mkay, installing now... ---\n"   

echo -e "\n--- Updating packages list ---\n"
sudo apt-get -qq update
echo -e "\n--- Updating packages list ---\n"
sudo apt-get -qq update

echo -e "\n--- Install MySQL specific packages and settings ---\n"
echo "mysql-server mysql-server/root_password password $DBPASSWD" | debconf-set-selections
echo "mysql-server mysql-server/root_password_again password $DBPASSWD" | debconf-set-selections
echo "phpmyadmin phpmyadmin/dbconfig-install boolean true" | debconf-set-selections
echo "phpmyadmin phpmyadmin/app-password-confirm password $DBPASSWD" | debconf-set-selections
echo "phpmyadmin phpmyadmin/mysql/admin-pass password $DBPASSWD" | debconf-set-selections
echo "phpmyadmin phpmyadmin/mysql/app-pass password $DBPASSWD" | debconf-set-selections
echo "phpmyadmin phpmyadmin/reconfigure-webserver multiselect none" | debconf-set-selections
sudo apt-get -y install mysql-server phpmyadmin > /dev/null 2>&1
# sudo apt-get -y install phpmyadmin

echo -e "\n--- Setting up our MySQL user and db ---\n"
mysql -uroot -p$DBPASSWD -e "CREATE DATABASE $DBNAME"
mysql -uroot -p$DBPASSWD -e "grant all privileges on $DBNAME.* to '$DBUSER'@'localhost' identified by '$DBPASSWD'"

echo -e "\n--- Installing PHP-specific packages ---\n"
sudo apt-get -qq update
sudo apt-add-repository -y ppa:ondrej/php

# apt-get -y install php5 apache2 libapache2-mod-php5 php5-curl php5-gd php5-mcrypt php5-mysql php-apc > /dev/null 2>&1
sudo apt-get -y install php8.1 apache2 libapache2-mod-php8.1 php8.1-curl php8.1-gd php8.1-mcrypt php8.1-mysql
#  php-apc 
# > /dev/null 2>&1

sudo apt-get -qq update
sudo apt -y install php8.1-cli php8.1-common php8.1-fpm
sudo apt -y install mc
sudo apt -y install net-tools
sudo a2enconf php8.1-fpm

echo -e "\n--- Enabling mod-rewrite ---\n"
sudo a2enmod rewrite > /dev/null 2>&1

echo -e "\n--- Allowing Apache override to all ---\n"
sed -i "s/AllowOverride None/AllowOverride All/g" /etc/apache2/apache2.conf

echo -e "\n--- Setting document root to public directory ---\n"




sudo echo -e "\n--- We definitly need to see the PHP errors, turning them on ---\n"
sudo sed -i "s/error_reporting = .*/error_reporting = E_ALL/" /etc/php/7.2/apache2/php.ini
sudo sed -i "s/display_errors = .*/display_errors = On/" /etc/php/7.2/apache2/php.ini

sudo echo -e "\n--- Turn off disabled pcntl functions so we can use Boris ---\n"
# sed -i "s/disable_functions = .*//" /etc/php5/cli/php.ini

sudo echo -e "\n--- Configure Apache to use phpmyadmin ---\n"
sudo echo -e "\n\nListen 81\n" >> /etc/apache2/ports.conf
sudo cat > /etc/apache2/conf-available/phpmyadmin.conf << "EOF"
<VirtualHost *:81>
    ServerAdmin webmaster@localhost
    DocumentRoot /usr/share/phpmyadmin
    DirectoryIndex index.php
    ErrorLog ${APACHE_LOG_DIR}/phpmyadmin-error.log
    CustomLog ${APACHE_LOG_DIR}/phpmyadmin-access.log combined
</VirtualHost>
EOF
sudo a2enconf phpmyadmin > /dev/null 2>&1

sudo echo -e "\n--- Add environment variables to Apache ---\n"
sudo cat > /etc/apache2/sites-enabled/000-default.conf <<EOF
<VirtualHost *:80>
    DocumentRoot /var/www/html
    ErrorLog \${APACHE_LOG_DIR}/error.log
    CustomLog \${APACHE_LOG_DIR}/access.log combined
    SetEnv APP_ENV $APPENV
    SetEnv DB_HOST $DBHOST
    SetEnv DB_NAME $DBNAME
    SetEnv DB_USER $DBUSER
    SetEnv DB_PASS $DBPASSWD
</VirtualHost>
EOF

echo -e "\n--- Restarting Apache ---\n"
sudo service apache2 restart > /dev/null 2>&1

# echo -e "\n--- Installing Composer for PHP package management ---\n"
# curl --silent https://getcomposer.org/installer | php > /dev/null 2>&1
# mv composer.phar /usr/local/bin/composer

# echo -e "\n--- Updating project components and pulling latest versions ---\n"
# cd /vagrant
# sudo -u vagrant -H sh -c "composer install" > /dev/null 2>&1
# cd /vagrant/client

# echo -e "\n--- Add environment variables locally for artisan ---\n"

# cat >> /home/vagrant/.bashrc <<EOF

#######################
sudo rm -rf /var/www
sudo mkdir /var/www
sudo chown vagrant.vagrant /var/www
ln -fs /vagrant/html/ /var/www/html
ln -fs /usr/share/phpmyadmin /var/www/phpmyadmin
# ln -fs /vagrant/hrgraphs/backend/web /var/www/web/admin
######################

# Set envvars
export APP_ENV=$APPENV
export DB_HOST=$DBHOST
export DB_NAME=$DBNAME
export DB_USER=$DBUSER
export DB_PASS=$DBPASSWD
EOF

