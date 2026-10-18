#!/bin/sh
set -eu
umask 077
read_setting() {
    name=$1
    eval 'direct=${'"$name"'-}'
    eval 'file=${'"$name"'_FILE-}'
    if [ -n "$direct" ] && [ -n "$file" ]; then
        echo 'error: conflicting certificate settings' >&2
        return 1
    fi
    if [ -n "$file" ]; then cat -- "$file"; else printf '%s' "$direct"; fi
}
CERTBOT_CERT_DIR=${CERTBOT_CERT_DIR:-/etc/letsencrypt}
CERTBOT_EMAIL=$(read_setting CERTBOT_EMAIL)
CERTBOT_DOMAINS=$(read_setting CERTBOT_DOMAINS)
: "${CERTBOT_EMAIL:?Missing certificate email}" "${CERTBOT_DOMAINS:?Missing certificate domains}"
mkdir -p "$CERTBOT_CERT_DIR"
contents=$(ls -A "$CERTBOT_CERT_DIR")
if [ -n "$contents" ]; then
    echo 'error: non-empty certificate directory' >&2
    exit 1
fi
set -- certonly --standalone --config-dir "$CERTBOT_CERT_DIR" \
    -m "$CERTBOT_EMAIL" -d "$CERTBOT_DOMAINS" --keep-until-expiring \
    --non-interactive --agree-tos --no-eff-email
if [ "${CERTBOT_STAGING+x}" = x ]; then set -- "$@" --test-cert; fi
echo 'creating certificates'
certbot "$@"
printf 'created %s\n' "$(date)" >> "$CERTBOT_CERT_DIR/.renewal-history"
