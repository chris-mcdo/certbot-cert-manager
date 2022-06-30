#!/bin/sh

# file_env
# set a variable from a file or from the environment
# does not export the variable
# usage: file_env VAR [DEFAULT]
#    e.g.: file_env 'XYZ_DB_PASSWORD' 'example'
file_env() {
    local var="$1"
    local fileVar="${var}_FILE"
    local def="${2:-}"
    if [ "$(eval echo \$$var)" ] && [ "$(eval echo \$$fileVar)" ]; then
        echo >&2 "error: both $var and $fileVar are set (but are exclusive)"
        exit 1
    fi
    local val="$def"
    if [ "$(eval echo \$$var)" ]; then
        val="$(eval echo \$$var)"
    elif [ "$(eval echo \$$fileVar)" ]; then
        val="$(cat "$(eval echo \$$fileVar)")"
    fi
    eval $var=\$val
    unset "$fileVar"
}

CERTBOT_CERT_DIR="/etc/letsencrypt"

file_env 'CERTBOT_EMAIL'
file_env 'CERTBOT_DOMAINS'
CERTBOT_STAGING=${CERTBOT_STAGING+--test-cert}

# check directory is empty before creating
if [ "$(ls -A ${CERTBOT_CERT_DIR})" ]; then
    echo "error: non-empty certificate directory"
    exit 1
fi

echo "creating certificates"
certbot certonly --standalone \
    $CERTBOT_STAGING \
    -m $CERTBOT_EMAIL \
    -d $CERTBOT_DOMAINS \
    --keep-until-expiring \
    --non-interactive \
    --agree-tos \
    --no-eff-email
