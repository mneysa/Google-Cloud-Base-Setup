#! /bin/bash

#remove nospoof problem
sudo sed -i '/nospoof/d' /etc/host.conf 

sudo apt-get update -y
echo openssh-server hold | sudo dpkg --set-selections
sudo apt-get install -y unzip
sudo apt-get install -y aptitude
sudo apt-get install -y nfs-common
sudo apt-get install -y tofrodos

sudo gsutil cp gs://staging-webservbucket/service_account/scratch-staging-221817-8b1567b2b289.json /opt/


# fetch/install google logging agent
curl -sSO https://dl.google.com/cloudagents/add-monitoring-agent-repo.sh
sudo bash add-monitoring-agent-repo.sh
sudo apt-get -y update

sudo apt-get install -y 'stackdriver-agent=6.*'
sudo service stackdriver-agent start


# install php7.2-fpm and install necessary extensions

sudo apt-get install -y php
sudo apt-get install -y php-pear php-fpm php-dev php-zip php-curl php-xmlrpc php-gd php-mysql php-mbstring php-xml 

sudo add-apt-repository ppa:ondrej/php
sudo apt-get update
sudo update-alternatives --set php /usr/bin/php7.2
sudo update-alternatives --set phar /usr/bin/phar7.2
sudo update-alternatives --set phar.phar /usr/bin/phar.phar7.2
sudo update-alternatives --set phpize /usr/bin/phpize7.2
sudo update-alternatives --set php-config /usr/bin/php-config7.2

#Add Redis

sudo apt-get install -y php-redis


cd /home/ubuntu
sudo -H -u ubuntu bash -c 'gcloud source repos clone scratch-deployment'
cd /home/ubuntu/scratch-deployment

#Update php max request
sudo cp /home/ubuntu/scratch-deployment/config/scratchpay.com/laravel_conf/www.conf /etc/php/7.2/fpm/pool.d/www.conf

# install nodejs and npm
curl -sL https://deb.nodesource.com/setup_8.x | sudo -E bash -
sudo apt-get install -y nodejs
sudo apt-get install -y npm 

# install mysql client and proxy

sudo apt-get install -y mysql-client
sudo wget https://dl.google.com/cloudsql/cloud_sql_proxy.linux.amd64 -O /usr/sbin/cloud_sql_proxy
sudo chmod +x /usr/sbin/cloud_sql_proxy

gsutil cp gs://staging-webservbucket/cloud_sql/staging-cloud-sql.json /opt/cloud-sql.json


# fetch and install composer and laravel

curl -sS https://getcomposer.org/installer | sudo php -- --install-dir=/usr/local/bin --filename=composer

# add nginx signing key and install nginx
sudo apt-get purge -y apache2
sudo apt-get install -y nginx


## perform a bit of cleanup in the nginx folders

sudo rm -r /etc/nginx/conf.d
sudo rm /etc/nginx/sites-available/default
sudo rm /etc/nginx/sites-enabled/default




## install the web app - note this command is done as user www-data 
## as this is the owner of the folder and its contents 


sudo -H -u ubuntu bash -c 'composer install'
sudo -H -u ubuntu bash -c 'composer require google/cloud-logging'
sudo -H -u ubuntu bash -c 'php artisan clear-compiled'
sudo -H -u ubuntu bash -c 'setfacl -d -m g:www-data:rw /var/www/staging.scratchpay.com/storage/logs'
sudo -H -u ubuntu bash -c 'composer dump-autoload'
sudo -H -u ubuntu bash -c 'php artisan config:cache'
sudo phpenmod redis

GIT_SHORT_HASH=`git rev-parse --short HEAD`
sed -i -E "s/^(VERSION=[^-]+).*$/\1-${GIT_SHORT_HASH}/" .env


#Change PHP max_execution_time to 90
sudo sed -i -e 's/max_execution_time = 30/max_execution_time = 90/g' /etc/php/7.2/fpm/php.ini

#Secure PHP 
sudo php -c /etc/php/7.2/cli /etc/php/7.2/cli -d expose_php=off
## Restart php
sudo service php7.2-fpm restart

## reload the nginx configuration files so the application will serve

sudo service nginx reload

#set tcp_max_alive for sql 

echo 'net.ipv4.tcp_keepalive_time = 60' | sudo tee -a /etc/sysctl.conf
sudo /sbin/sysctl --load=/etc/sysctl.conf


sudo gsutil cp gs://staging-webservbucket/hardening/hardening.sh /opt/
sudo chmod +x /opt/hardening.sh
sudo bash /opt/hardening.sh



