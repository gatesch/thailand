FROM php:5.6-apache
COPY index.php /var/www/html/index.php
COPY template /var/www/html/template
COPY js /var/www/html/js
COPY fonts /var/www/html/fonts
COPY css /var/www/html/css
COPY composer.json /var/www/html/composer.json
RUN service apache2 restart
EXPOSE 80
