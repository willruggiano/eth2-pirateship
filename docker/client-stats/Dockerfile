FROM ubuntu:latest

ARG USER=stats
ARG UID=10002

RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y curl gnupg

RUN adduser \
    --disabled-password \
    --gecos "" \
    --shell "/sbin/nologin" \
    --uid "${UID}" \
    "${USER}"

USER ${USER}
WORKDIR /home/${USER}

RUN curl https://raw.githubusercontent.com/prysmaticlabs/prysm/master/prysm.sh --output prysm.sh && chmod +x prysm.sh

ENTRYPOINT ["./prysm.sh", "client-stats"]
