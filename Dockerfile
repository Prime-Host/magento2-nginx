FROM primehost/nginx
MAINTAINER Kevin Nordloh <mail@legendary-server.de>

# update before install
RUN apt-get update
RUN apt-get -y upgrade

# install composer
RUN apt-get -y install composer

# clean up unneeded packages
RUN apt-get --purge autoremove -y

# custom settings for magento2
ADD ./nginx-default.conf /etc/nginx/sites-available/default
RUN chown -R www-data:www-data /var/lib/php/sessions/

# magento2 initialization and startup script
ADD ./magento2-start.sh /magento2-start.sh
RUN chmod 755 /magento2-start.sh

CMD ["/bin/bash", "/magento2-start.sh"]
