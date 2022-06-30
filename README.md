# certbot-cert-manager

An image to automate web certificate creation and renewal using certbot / letsencrypt.

## Creating certificates

Certificates are created using the standalone authentication plugin.

It should be run as a one-off task. For example:

```
docker volume create web-certificates
docker volume create letsencrypt-data
docker run \
    -it \
    --rm \
    --mount type=volume,source=web-certificates,target=/etc/letsencrypt \
    --mount type=volume,source=letsencrypt-data,target=/var/lib/letsencrypt \
    -p "80:80" \
    --env CERTBOT_EMAIL=${YOUR_EMAIL_ADDRESS} \
    --env CERTBOT_DOMAINS=${YOUR_DOMAINS} \
    --name certificate-creator \
    ghcr.io/chris-mcdo/certbot-cert-manager:latest \
    /usr/local/bin/create-certs.sh
```

Certificates are stored in the named volume `web-certificates`.
(Alternatively, you could use a bind-mount.)

If you have a server listening on port 80, you will need to stop it before running this command, since the standalone plugin will try to listen on port 80.

## Renewing certificates

Certificates are renewed automatically using the webroot authentication plugin.

To set this up, you will need to serve the ACME challenge files from your web server.

For example, in nginx you should add this to your main server configuration:

```
# main server config
server { 
    ...

    # ACME challenge files
    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }
}
```

Then, to automatically renew certificates:

```
docker volume create acme-challenge-files
docker run \
    -d \
    --mount type=volume,source=web-certificates,target=/etc/letsencrypt \
    --mount type=volume,source=letsencrypt-data,target=/var/lib/letsencrypt \
    --mount type=volume,source=acme-challenge-files,target=/var/www/letsencrypt \
    --name certificate-renewer \
    ghcr.io/chris-mcdo/certbot-cert-manager:latest \
    crond -f
docker run \
    -d \
    --mount type=volume,source=web-certificates,target=/etc/letsencrypt \
    --mount type=volume,source=acme-challenge-files,target=/var/www/letsencrypt \
    --name frontend-web-server \
    -p 80:80 \
    -p 443:443 \
    nginx:1-alpine
```

The `certbot renew` command is run via cron once per day (by default).

## Notes

Letsencrypt enforces rate limits on creation / renewal of real certificates.
You can use test certificates instead by setting `CERTBOT_STAGING=true` when creating the certificates with `create-certs.sh`.

By running `create-certs.sh` you are agreeing to the ACME server's Subscriber Agreement.

If the `/etc/letsencrypt` directory mounted into the `certbot-cert-manager` container is not empty, then certificate creation will fail.

To generate certificates for multiple domains, use a comma-separated list when specifying the $CERTBOT_DOMAINS variable. (E.g. `CERTBOT_DOMAINS=example.com,www.example.com`.)

## License

See the
[License](https://github.com/chris-mcdo/certbot-cert-manager/blob/main/LICENSE)
file for details.
