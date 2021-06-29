ARG TAG
FROM ethereum/client-go:${TAG}

ARG USER=geth
ARG UID=10001

# So we can switch to non-root user if started as root
RUN apk add --no-cache su-exec ca-certificates bash tzdata

RUN adduser \
    --disabled-password \
    --gecos "" \
    --shell "/sbin/nologin" \
    --uid "${UID}" \
    "${USER}"

RUN mkdir -p /var/lib/geth && chown ${USER}:${USER} /var/lib/geth

COPY ./docker-entrypoint.sh /usr/local/bin/

ENTRYPOINT ["docker-entrypoint.sh", "geth"]

