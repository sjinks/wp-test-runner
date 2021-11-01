# wp-test-runner

[![Build Docker image](https://github.com/sjinks/wp-test-runner/actions/workflows/build-image.yml/badge.svg)](https://github.com/sjinks/wp-test-runner/actions/workflows/build-image.yml)
[![Image Security Scan](https://github.com/sjinks/wp-test-runner/actions/workflows/imagescan.yml/badge.svg)](https://github.com/sjinks/wp-test-runner/actions/workflows/imagescan.yml)

Test runner for WordPress plugins

## Usage

```bash
docker run \
	--network "${NETWORK_NAME}" \
	-e WORDPRESS_VERSION \
	-e WP_MULTISITE \
	-e MYSQL_USER \
	-e MYSQL_PASSWORD \
	-e MYSQL_DATABASE \
	-e MYSQL_HOST \
	-v "$(pwd):/app" \
	wildwildangel/wp-test-runner
```

**Parameters and environment variables:**
  * `NETWORK_NAME` is the name of the network (created with `docker network create`) where MySQL server resides.
  * `WORDPRESS_VERSION` is the version of WordPress to use. If the version specified is not among the preinstalled ones, it will be downloaded and configured. Preinstalled versions:
    * 5.3.9
    * 5.4.7
    * 5.5.6
    * 5.6.5
    * 5.7.3
    * 5.8.1 (aliased as `latest`)
    * nightly
  * `WP_MULTISITE`: 0 if run tests for the "single site" mode, 1 for the WPMU mode
  * `MYSQL_USER`: MySQL user name (defaults to `wordpress`)
  * `MYSQL_PASSWORD`: MySQL user password (defaults to `wordpress`)
  * `MYSQL_DATABASE`: MySQL database for tests (defaults to `wordpress_test`). **WARNING:** this must be an empty database, as its content will be erased.
  * `MYSQL_HOST`: hostname where MySQL server runs

## Sample Script to Run Tests

```bash
#!/bin/sh

set -x

export WORDPRESS_VERSION="${1:-latest}"
export WP_MULTISITE="${2:-0}"

if [ $# -ge 2 ]; then
	shift 2
elif [ $# -ge 1 ]; then
	shift 1
fi

echo "--------------"
echo "Will test with WORDPRESS_VERSION=${WORDPRESS_VERSION} and WP_MULTISITE=${WP_MULTISITE}"
echo "--------------"
echo

MARIADB_VERSION="10.3"
UUID=$(date +%s000)
NETWORK_NAME="tests-${UUID}"

export MYSQL_HOST="db-${UUID}"
export MYSQL_USER=wordpress
export MYSQL_PASSWORD=wordpress
export MYSQL_DATABASE=wordpress_test
export MYSQL_ROOT_PASSWORD=wordpress
export MYSQL_INITDB_SKIP_TZINFO=1

docker network create "${NETWORK_NAME}"
db=$(docker run --network "${NETWORK_NAME}" --name "${MYSQL_HOST}" -e MYSQL_ROOT_PASSWORD -e MARIADB_INITDB_SKIP_TZINFO -e MYSQL_USER -e MYSQL_PASSWORD -e MYSQL_DATABASE -d "mariadb:${MARIADB_VERSION}")

cleanup() {
	docker rm -f "${db}"
	docker network rm "${NETWORK_NAME}"
}

trap cleanup EXIT

docker run \
	--network "${NETWORK_NAME}" \
	-e WORDPRESS_VERSION \
	-e WP_MULTISITE \
	-e MYSQL_USER \
	-e MYSQL_PASSWORD \
	-e MYSQL_DATABASE \
	-e MYSQL_HOST \
	-v "$(pwd):/app" \
	wildwildangel/wp-test-runner "/usr/local/bin/runner" "$@"
```
