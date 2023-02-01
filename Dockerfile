FROM certbot/certbot:v2.2.0

# Remove crontab junk
RUN set -eux; \
    rm -rf /etc/crontabs/* /etc/periodic

# Entrypoint scripts
COPY --chmod=0755 create-certs.sh renew-certs.sh deploy/*.sh /usr/local/bin/

# Custom crontabs
COPY --chmod=0600 crontabs/* /etc/crontabs/

ENTRYPOINT []

CMD ["crond", "-f", "-d", "5"]
