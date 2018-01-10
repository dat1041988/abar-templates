FROM nginx:1.11

RUN apt-get update -y && \
    apt-get install -y --force-yes git curl php5-fpm php5-cli php5-common \
            php5-mcrypt php5-curl php5-mysql php5-sqlite && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# PHP-FPM settings
RUN sed -i "/user  nginx;/c user  root;"                           /etc/nginx/nginx.conf && \
    sed -i "/memory_limit = /c memory_limit = 128M"                /etc/php5/fpm/php.ini && \
    sed -i "/max_execution_time = /c max_execution_time = 300"     /etc/php5/fpm/php.ini && \
    sed -i "/upload_max_filesize = /c upload_max_filesize = 50M"   /etc/php5/fpm/php.ini && \
    sed -i "/post_max_size = /c post_max_size = 50M"               /etc/php5/fpm/php.ini && \
    sed -i "/user = /c user = root"                                /etc/php5/fpm/pool.d/www.conf && \
    sed -i "/;listen.mode = /c listen.mode = 0666"                 /etc/php5/fpm/pool.d/www.conf && \
    sed -i "/listen.owner = /c listen.owner = root"                /etc/php5/fpm/pool.d/www.conf && \
    sed -i "/listen.group = /c listen.group = root"                /etc/php5/fpm/pool.d/www.conf && \
    sed -i "/listen = /c listen = 127.0.0.1:9000"                  /etc/php5/fpm/pool.d/www.conf && \
    sed -i "/;clear_env = /c clear_env = no"                       /etc/php5/fpm/pool.d/www.conf

# Log aggregation
RUN ln -sf /dev/stdout /var/log/nginx/access.log && \
    ln -sf /dev/stderr /var/log/nginx/error.log && \
    ln -sf /dev/stdout /var/log/php5-fpm.log

EXPOSE 8080

ENTRYPOINT ["/bin/sh", "/var/www/entrypoint.sh"]
CMD ["/var/www/start.sh"]

COPY ./config/nuget.conf /etc/nginx/conf.d/default.conf
COPY ./config/*.sh /var/www/

WORKDIR /var/www
COPY server .
RUN chown -R 1001:0 /var/www /var/cache/nginx /var/run && \
    chmod -R a+rwx /var/www /var/cache/nginx /var/run

# Set randomly generated API key
RUN echo $(date +%s | sha256sum | base64 | head -c 32; echo) > .api-key && \
    echo "Auto-Generated NuGet API key: $(cat .api-key)" && \
    sed -i inc/config.php -e "s/ChangeThisKey/$(cat .api-key)/"

USER 1001
