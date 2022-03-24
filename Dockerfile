FROM alpine:3.15.2 AS pli
RUN apk -U upgrade && apk add --no-cache gnu-libiconv

FROM alpine:3.15.2

RUN \
	apk -U upgrade && \
	apk add --no-cache php7 php7-common php7-dom php7-pdo php7-mbstring php7-zip php7-sysvsem php7-sysvshm php7-sysvmsg php7-shmop php7-sockets \
		php7-zlib php7-curl php7-simplexml php7-xml php7-opcache php7-dom php7-xmlreader php7-xmlwriter php7-tokenizer php7-session php7-fileinfo \
		php7-json php7-posix php7-pear php7-phar php7-gd php7-gettext php7-gmp php7-iconv php7-imagick php7-imap php7-intl php7-mysqli php7-mysqlnd \
		php7-pcntl php7-pdo_mysql php7-pdo_sqlite php7-xsl php7-openssl php7-sodium php7-pecl-imagick php7-pecl-apcu php7-pecl-xdebug \
		git subversion jq && \
	echo "zend_extension=xdebug.so" >> /etc/php7/conf.d/50_xdebug.ini && \
	echo "xdebug.mode=coverage" >> /etc/php7/conf.d/50_xdebug.ini

RUN \
	adduser -D user && \
	install -d -o user -g user -m 0777 /app /wordpress && \
	wget -q https://getcomposer.org/installer -O - | php -- --install-dir=/usr/bin/ --filename=composer

RUN \
	wget -O /usr/local/bin/phpunit7 https://phar.phpunit.de/phpunit-7.phar && chmod +x /usr/local/bin/phpunit7 && \
	wget -O /usr/local/bin/phpunit8 https://phar.phpunit.de/phpunit-8.phar && chmod +x /usr/local/bin/phpunit8 && \
	wget -O /usr/local/bin/phpunit9 https://phar.phpunit.de/phpunit-9.phar && chmod +x /usr/local/bin/phpunit9

COPY --from=pli /usr/lib/preloadable_libiconv.so /usr/lib/preloadable_libiconv.so
COPY install-wp.sh /usr/local/bin/install-wp
COPY runner.sh /usr/local/bin/runner

ENV LD_PRELOAD=/usr/lib/preloadable_libiconv.so
USER user

RUN \
	for version in $(wget https://api.wordpress.org/core/version-check/1.7/ -q -O - | jq -r '[.offers[].version] | unique | map(select( . >= "5.3")) | .[]') latest nightly; do \
		install-wp "${version}" & \
	done && \
	wait

RUN composer global require phpunit/phpunit:^7 yoast/phpunit-polyfills:^1
WORKDIR /app
VOLUME ["/app"]

CMD ["/usr/local/bin/runner"]
