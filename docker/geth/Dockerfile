ARG TAG
FROM ethereum/client-go:${TAG}

ARG USER=geth
ARG UID=10001

RUN adduser \
    --disabled-password \
    --gecos "" \
    --shell "/sbin/nologin" \
    --uid "${UID}" \
    "${USER}"

RUN mkdir -p /var/lib/geth && chown -R ${USER}:${USER} /var/lib/geth

USER ${USER}

