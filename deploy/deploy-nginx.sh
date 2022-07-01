#!/bin/sh
# Script to be run on successful renewal / creation of certs.
# it performs the following functions:
# (1) Downloads recommended SSL settings from mozilla.org
# (2) Creates / updates a "renewal history" file
#     If you watch this file with inotifyd, you can
#     reload your nginx configuration upon successful cert renewal.

CERTBOT_CERT_DIR="/etc/letsencrypt"
CERTBOT_HISTORY_PATH="${CERTBOT_CERT_DIR}/.renewal-history"

NGINX_SSL_PARAMS_PATH="${CERTBOT_CERT_DIR}/ssl-dhparams.pem"
NGINX_SSL_PARAMS_URL="https://ssl-config.mozilla.org/ffdhe2048.txt"

echo "running deploy-nginx.sh (post-deploy script)"
echo

# Update recommended SSL settings
echo "updating recommended ssl settings"
echo

wget -O "${NGINX_SSL_PARAMS_PATH}" "${NGINX_SSL_PARAMS_URL}" || echo "warning: failed to update ssl dhparams"

# updating history file
echo "renewed $(date)" >> ${CERTBOT_HISTORY_PATH}
