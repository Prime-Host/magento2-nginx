FROM primehost/nginx
MAINTAINER Kevin Nordloh <mail@legendary-server.de>

# update before install
RUN apt-get update
RUN apt-get -y upgrade

# clean up unneeded packages
RUN apt-get --purge autoremove -y
RUN rm -r /usr/share/nginx/www

# Install Wordpress
RUN cd /usr/share/nginx/ \
    && git clone https://github.com/magento/magento2.git 

RUN mv /usr/share/nginx/magento2 /usr/share/nginx/www \
    && chown -R www-data:www-data /usr/share/nginx/www \
    && chmod -R 775 /usr/share/nginx/www

# Wordpress Initialization and Startup Script
ADD ./magento2-start.sh /magento2-start.sh
RUN chmod 755 /magento2-start.sh

CMD ["/bin/bash", "/magento2-start.sh"]
