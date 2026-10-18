#!/bin/sh
set -eu
CERTBOT_WEBROOT_DIR=${CERTBOT_WEBROOT_DIR:-/var/www/letsencrypt}
set -- renew --webroot --webroot-path "$CERTBOT_WEBROOT_DIR"
if [ "${CERTBOT_DRY_RUN+x}" = x ]; then set -- "$@" --dry-run; fi
if [ -n "${CERTBOT_DEPLOY_SCRIPT:-}" ]; then
    set -- "$@" --deploy-hook "$CERTBOT_DEPLOY_SCRIPT"
fi
echo "renewing certificates"
certbot "$@"
echo "renew finished"
