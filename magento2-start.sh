#!/bin/bash

# Create custom ssh_user with sudo privileges
useradd -m -d /home/$PRIMEHOST_USER -G root -s /bin/bash $PRIMEHOST_USER \
	&& usermod -a -G $PRIMEHOST_USER $PRIMEHOST_USER \
	&& usermod -a -G sudo $PRIMEHOST_USER

# Set passwords for the ssh_user and root
echo "$PRIMEHOST_USER:$PRIMEHOST_PASSWORD" | chpasswd
echo "root:$PRIMEHOST_PASSWORD" | chpasswd

# Custom user for nginx and php
sed -i s/www-data/$PRIMEHOST_USER/g /etc/nginx/nginx.conf
sed -i s/www-data/$PRIMEHOST_USER/g /etc/php/7.0/fpm/pool.d/www.conf

# Install magento2
if [ ! -f /usr/share/nginx/www/app/etc/env.php ]; then
cd /usr/share/nginx/ \
    && git clone -b 2.2 https://github.com/magento/magento2.git www \
    && rm -r www/.git
fi

# set custom user for magento files
chown -R $PRIMEHOST_USER:$PRIMEHOST_USER /usr/share/nginx/www

# special permissions for magento2
chown -R $PRIMEHOST_USER:$PRIMEHOST_USER /var/lib/php/sessions/

# start all services
/usr/local/bin/supervisord -n -c /etc/supervisord.conf
