FROM nextcloud:25-fpm-alpine

#RUN apk add --no-cache procps libsmbclient imagemagick
# https://www.reddit.com/r/NextCloud/comments/9e5ljv/nextcloud_and_phpfpm_adjustments/
RUN sed -i -e 's/^pm\ =\ dynamic/pm\ =\ static/' /usr/local/etc/php-fpm.d/www.conf && \
    sed -i -e 's/^pm.max_children\ =\ 5/pm.max_children\ =\ 64/' /usr/local/etc/php-fpm.d/www.conf && \
    sed -i -e 's/^listen\ =\ 9000/listen\ =\ \/var\/run\/php-fpm-sock\/php-fpm.sock/' /usr/local/etc/php-fpm.d/zz-docker.conf && \
    echo "listen.mode = 0666" >> /usr/local/etc/php-fpm.d/zz-docker.conf
COPY assets/ee-pre-init.sh /
COPY assets/ee-init.sh /
COPY assets/entrypoint.sh /
#COPY assets/usr/lib/php/extensions/no-debug-non-zts-20190902/smbclient.so /usr/local/lib/php/extensions/no-debug-non-zts-20190902/smbclient.so
#COPY assets/usr/local/etc/php/conf.d/docker-php-ext-smbclient.ini /usr/local/etc/php/conf.d/docker-php-ext-smbclient.ini