ARG TAG
FROM prysmaticlabs/prysm-beacon-chain:${TAG} as prysm

FROM debian:buster-slim
COPY --from=prysm /app/cmd/beacon-chain/beacon-chain /usr/local/bin/

ARG USER=prysm
ARG UID=10001

RUN adduser \
    --disabled-password \
    --gecos "" \
    --shell "/sbin/nologin" \
    --uid "${UID}" \
    "${USER}"

RUN mkdir -p /var/lib/prysm && chown ${USER}:${USER} /var/lib/prysm

USER ${USER}

