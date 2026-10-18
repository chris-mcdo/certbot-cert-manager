FROM certbot/certbot:v5.8.0@sha256:f70ad0adbb7e117f0fe42a63c553f28ea451edabc0148757b6efcd9735acaa20

# Remove crontab junk
RUN set -eux; \
    rm -rf /etc/crontabs/* /etc/periodic

# Entrypoint scripts
COPY create-certs.sh renew-certs.sh deploy/*.sh /usr/local/bin/

# Custom crontabs
COPY crontabs/* /etc/crontabs/
RUN chmod 0755 /usr/local/bin/create-certs.sh /usr/local/bin/renew-certs.sh \
       /usr/local/bin/deploy-nginx.sh && chmod 0600 /etc/crontabs/*

ENTRYPOINT []

CMD ["crond", "-f", "-d", "5"]
