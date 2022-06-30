#!/bin/sh

CERTBOT_WEBROOT_DIR=${CERTBOT_WEBROOT_DIR:-/var/www/letsencrypt}
CERTBOT_DRY_RUN=${CERTBOT_DRY_RUN+--dry-run}

echo "renewing certificates"
echo

certbot renew \
    ${CERTBOT_DRY_RUN} \
    --webroot \
    --webroot-path ${CERTBOT_WEBROOT_DIR}

echo "renew finished"
echo