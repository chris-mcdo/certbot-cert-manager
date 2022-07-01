#!/bin/sh

CERTBOT_WEBROOT_DIR=${CERTBOT_WEBROOT_DIR:-/var/www/letsencrypt}
CERTBOT_DRY_RUN=${CERTBOT_DRY_RUN+--dry-run}
CERTBOT_DEPLOY_ARG=${CERTBOT_DEPLOY_SCRIPT:+--deploy-hook $CERTBOT_DEPLOY_SCRIPT}

echo "renewing certificates"
echo

certbot renew \
    ${CERTBOT_DRY_RUN} \
    --webroot \
    --webroot-path ${CERTBOT_WEBROOT_DIR} \
    ${CERTBOT_DEPLOY_ARG}

echo "renew finished"
echo
