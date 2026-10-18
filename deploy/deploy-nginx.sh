#!/bin/sh
# Signal Nginx after renewal; never replace working DH parameters with a failed download.
set -eu
umask 077
CERTBOT_CERT_DIR=${CERTBOT_CERT_DIR:-/etc/letsencrypt}
CERTBOT_HISTORY_PATH="$CERTBOT_CERT_DIR/.renewal-history"
NGINX_SSL_PARAMS_PATH="$CERTBOT_CERT_DIR/ssl-dhparams.pem"
NGINX_SSL_PARAMS_URL="https://ssl-config.mozilla.org/ffdhe2048.txt"
PARTIAL=$(mktemp "$CERTBOT_CERT_DIR/.dhparams.XXXXXX")
cleanup() { rm -f -- "$PARTIAL"; }
trap cleanup EXIT
trap 'exit 1' HUP INT TERM
if wget -O "$PARTIAL" "$NGINX_SSL_PARAMS_URL" \
    && grep -q '^-----BEGIN DH PARAMETERS-----$' "$PARTIAL" \
    && grep -q '^-----END DH PARAMETERS-----$' "$PARTIAL"; then
    chmod 0644 "$PARTIAL"
    mv -- "$PARTIAL" "$NGINX_SSL_PARAMS_PATH"
elif [ -s "$NGINX_SSL_PARAMS_PATH" ]; then
    echo 'warning: DH parameter refresh failed; keeping existing file' >&2
else
    echo 'error: DH parameter refresh failed and no existing file is available' >&2
    exit 1
fi
printf 'renewed %s\n' "$(date)" >> "$CERTBOT_HISTORY_PATH"
