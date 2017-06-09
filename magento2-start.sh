#!/bin/bash

# Create custom ssh_user with sudo privileges
useradd -m -d /home/$PRIMEHOST_USER -G root -s /bin/bash $PRIMEHOST_USER \
	&& usermod -a -G $PRIMEHOST_USER $PRIMEHOST_USER \
	&& usermod -a -G sudo $PRIMEHOST_USER

# Set passwords for the ssh_user and root
echo "$PRIMEHOST_USER:$PRIMEHOST_PASSWORD" | chpasswd
echo "root:$PRIMEHOST_PASSWORD" | chpasswd

# Install magento2
if [ ! -f /usr/share/nginx/www/app/etc/env.php ]; then
cd /usr/share/nginx/ \
    && rm  /usr/share/nginx/www/index.php \
    && git clone https://github.com/magento/magento2.git www \
    && chown -R www-data:www-data /usr/share/nginx/www \
    && chmod -R 775 /usr/share/nginx/www
fi

# start all services
/usr/local/bin/supervisord -n -c /etc/supervisord.conf
