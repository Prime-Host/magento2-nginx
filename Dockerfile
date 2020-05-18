FROM primehost/nginx:php7.1
MAINTAINER Kevin Nordloh <mail@legendary-server.de>

# update before install
RUN apt-get update

# install composer
RUN apt-get -y install composer logrotate

# higher max_input_vars
RUN sed -i -e "s/; max_input_vars\s*=\s*1000/max_input_vars = 5000000/g" /etc/php/*/fpm/php.ini \
&&  sed -i 's/su root syslog/#su root root/g' /etc/logrotate.conf

# clean up unneeded packages
RUN apt-get --purge autoremove -y

# custom nginx settings for magento2
ADD ./nginx-default.conf /etc/nginx/sites-available/default

# magento2 initialization and startup script
ADD ./magento2-start.sh /root/container-scripts/prime-host/magento2-start.sh
ADD ./logrotate.d/magento2 /etc/logrotate.d/magento2
RUN chmod 755 /root/container-scripts/prime-host/magento2-start.sh

CMD ["/bin/bash", "/root/container-scripts/prime-host/magento2-start.sh"]
