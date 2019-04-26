FROM camino.azurecr.io/cantinona-partial/toppers-cfg:1.9.7 as cfg

WORKDIR /tmp/sources/cfg
RUN mkdir -p /opt/sources/cfg
RUN git archive --format=tar HEAD | tar xCf /opt/sources/cfg -

FROM camino.azurecr.io/gcc-rene/v850-elf:14.01

COPY --from=cfg /opt/sources/cfg /opt/sources/cfg/
COPY --from=cfg /opt/sources/cfg/cfg /opt/bin/
