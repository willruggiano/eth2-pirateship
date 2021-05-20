FROM ubuntu as base

RUN apt-get update
RUN apt-get install -y software-properties-common
RUN add-apt-repository -y ppa:ethereum/ethereum && apt-get update
RUN apt-get install -y curl ethereum python3.9

RUN useradd -rm -d /home/barbosa -s /bin/bash barbosa
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN echo 'barbosa:barbosa' | chpasswd

WORKDIR /home/barbosa

RUN curl https://raw.githubusercontent.com/prysmaticlabs/prysm/master/prysm.sh --output prysm.sh && chmod +x prysm.sh
RUN ln -s /home/barbosa/prysm.sh /usr/local/bin/prysm

COPY rootfs /out
RUN chmod +x /out/usr/local/bin/docker-entrypoint.sh
RUN chown -R barbosa /out/

FROM base as runtime

COPY --from=base /out/ /

USER barbosa

ENTRYPOINT ["docker-entrypoint.sh"]

