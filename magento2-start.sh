#!/bin/bash

# Create custom ssh_user with sudo privileges
useradd -m -d /home/$PRIMEHOST_USER -G root -s /bin/zsh $PRIMEHOST_USER \
	&& usermod -a -G $PRIMEHOST_USER $PRIMEHOST_USER \
	&& usermod -a -G sudo $PRIMEHOST_USER

# Set passwords for the ssh_user and root
echo "$PRIMEHOST_USER:$PRIMEHOST_PASSWORD" | chpasswd
echo "root:$PRIMEHOST_PASSWORD" | chpasswd

# Custom user for nginx and php, disable access.log
sed -i s/www-data/$PRIMEHOST_USER/g /etc/nginx/nginx.conf
sed -i s_/var/log/nginx/access.log_off_g /etc/nginx/nginx.conf
sed -i s/www-data/$PRIMEHOST_USER/g /etc/php/*/fpm/pool.d/www.conf

# Remove index.php
rm /usr/share/nginx/www/index.php

# Download magento2
if [ ! -f /usr/share/nginx/www/app/etc/env.php ]; then
cd /usr/share/nginx/ \
    && git clone -b 2.2 https://github.com/magento/magento2.git www \
    && rm -r www/.git
fi

# Enviroment Variables for cronjob and backup folder
printenv > /etc/environment
sed -i s,/root,/home/$PRIMEHOST_USER,g /etc/environment
if [ ! -f /home/$PRIMEHOST_USER/backup ]; then
    mkdir /home/$PRIMEHOST_USER/backup
fi

# insert cronjob
if [ ! -f /var/spool/cron/crontabs/$PRIMEHOST_USER ]; then
sudo -u $PRIMEHOST_USER bash << EOF
crontab -l | { cat; echo "TZ=Europe/Berlin
SHELL=/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin

* * * * * perl -le 'sleep rand 40' && php /usr/share/nginx/www/bin/magento cron:run | grep -v 'Ran jobs by schedule' >> /usr/share/nginx/www/var/log/magento.cron.log && php /usr/share/nginx/www/update/cron.php >> /usr/share/nginx/www/var/log/update.cron.log && php /usr/share/nginx/www/bin/magento setup:cron:run >> /usr/share/nginx/www/var/log/setup.cron.log
0 3 * * * mysqldump -u"root" -p"$PRIMEHOST_PASSWORD" -h"$PRIMEHOST_DOMAIN"-db magento2 > /home/$PRIMEHOST_USER/backup/dump.sql"; } | crontab -
EOF
fi

# set custom user for magento files
chown -R $PRIMEHOST_USER:$PRIMEHOST_USER /usr/share/nginx/www

# special permissions for magento2
chown -R $PRIMEHOST_USER:$PRIMEHOST_USER /var/lib/php/sessions/

# composer install
cd /usr/share/nginx/www
su -c "composer install" -m "$PRIMEHOST_USER"

# Install magento2
cd /usr/share/nginx/www/
su $PRIMEHOST_USER -s /bin/bash -c "php -f bin/magento setup:install --base-url=https://$PRIMEHOST_DOMAIN/ --backend-frontname=admin --db-host=$PRIMEHOST_DOMAIN-db --db-name=magento2 --db-user=root --db-password=$PRIMEHOST_PASSWORD --admin-firstname=Magento --admin-lastname=User --admin-email=$LETSENCRYPT_EMAIL --admin-user=$PRIMEHOST_USER --admin-password=$PRIMEHOST_PASSWORD --language=de_DE --currency=EUR"

# start all services
/usr/local/bin/supervisord -n -c /etc/supervisord.conf
