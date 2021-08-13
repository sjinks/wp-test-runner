#!/bin/sh

set -x
set -e

: "${MYSQL_USER:="wordpress"}"
: "${MYSQL_PASSWORD:="wordpress"}"
: "${MYSQL_DB:="wordpress_test"}"
: "${MYSQL_HOST:="db"}"
: "${WORDPRESS_VERSION:="latest"}"

if [ ! -d "/wordpress/wordpress-${WORDPRESS_VERSION}" ] || [ ! -d "/wordpress/wordpress-tests-lib-${WORDPRESS_VERSION}" ]; then
	install-wp "${WORDPRESS_VERSION}"
fi

(
	cd "/wordpress/wordpress-tests-lib-${WORDPRESS_VERSION}" && \
	cp -f wp-tests-config-sample.php wp-tests-config.php && \
	sed -i "s/youremptytestdbnamehere/${MYSQL_DB}/; s/yourusernamehere/${MYSQL_USER}/; s/yourpasswordhere/${MYSQL_PASSWORD}/; s|localhost|${MYSQL_HOST}|" wp-tests-config.php && \
	sed -i "s:dirname( __FILE__ ) . '/src/':'/tmp/wordpress/':" wp-tests-config.php
)

rm -rf /tmp/wordpress /tmp/wordpress-tests-lib
ln -sf "/wordpress/wordpress-${WORDPRESS_VERSION}" /tmp/wordpress
ln -sf "/wordpress/wordpress-tests-lib-${WORDPRESS_VERSION}" /tmp/wordpress-tests-lib

echo "Waiting for MySQL..."
while ! nc -z "${MYSQL_HOST}" 3306; do
	sleep 0.5
done

echo "Running tests..."
if [ -f /app/phpunit.xml ] || [ -f /app/phpunit.xml.dist ]; then
	if [ -x /app/vendor/bin/phpunit ]; then
		/app/vendor/bin/phpunit "$@"
	else
		phpunit "$@"
	fi
else
	echo "Unable to find phpunit.xml or phpunit.xml.dist"
	ls -lha /app
	exit 1
fi
