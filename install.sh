#!/bin/bash

echo "Installing PHP FPM 7.4 and extensions..."
{
sudo apt update;  sudo apt install -y nginx php7.4-fpm php7.4-curl php7.4-zip php7.4-gd php7.4-pgsql
}&> /dev/null

echo "Configuring PHP 7.4..."
{
sudo sed -i "s/www-data/$(whoami)/" /etc/php/7.4/fpm/pool.d/www.conf 
sudo mkdir -p /run/php
}&> /dev/null


echo "Installing Nginx..."
{
sudo apt install -y nginx 
}&> /dev/null

echo "Configuring Nginx..."
{
sudo cp ./default.nginx.conf /etc/nginx/sites-enabled/default
sudo sed -i "s#root /var/www/html;#root /home/$(whoami)/www;#" /etc/nginx/sites-enabled/default
sudo sed -i "s/user www-data;/user $(whoami);/" /etc/nginx/nginx.conf
mkdir -p /home/$(whoami)/www
if [ ! -d "/home/$(whoami)/www" ]; then
    cp -R /var/www/html/. "$destination"
    echo "Copied contents from /var/www/html/ to $destination"
else
    echo "$destination already exists. Skipping copy."
fi
}&> /dev/null


echo "Installing MariaDB..."
{
# We might need to remove some legacy packages
# We might need to point the storage to the home folder
sudo apt install -y mariadb-server
}&> /dev/null

echo "Configuring MariaDB..."
{
sudo service mariadb stop
sudo mkdir -p /run/mysqld
if [ ! -d "/home/$(whoami)/mysql" ] || [ "$1" == "--first-run" ]; then
    mkdir -p /home/$(whoami)/mysql
    sudo mysql_install_db --datadir=/home/$(whoami)/mysql
    echo "Created new MySQL datadir in /home/$(whoami)"
else
    echo "MySQL datadir already exists in /home/$(whoami). Leaving as-is."
fi
sudo sed -i "s#/var/lib/mysql#/home/$(whoami)/mysql#" /etc/mysql/mariadb.conf.d/50-server.cnf
sudo service mariadb start
sudo mysqladmin -u root password 'newpass'
}



if [ "$1" == "--first-run" ]; then
    sudo mysqladmin -uroot -pnewpass create opencart
    cd `mktemp -d`
    echo "Installing OpenCart..."
    {
    wget https://github.com/opencart/opencart/releases/download/3.0.3.9/opencart-3.0.3.9.zip
    unzip *
    rm -rf /home/$(whoami)/storage
    rm -rf /home/$(whoami)/www/*
    mv upload/* /home/$(whoami)/www/
    }&> /dev/null
    php /home/$(whoami)/www/install/cli_install.php install --db_hostname localhost --db_username root --db_password newpass --db_database opencart --db_driver mysqli --db_port 3306 --username admin --password 1 --email youremail@example.com --http_server https://8080-$WEB_HOST/
    rm -rf /home/$(whoami)/www/install
fi


sudo service php7.4-fpm restart && sudo service nginx restart  && sudo service mariadb restart
