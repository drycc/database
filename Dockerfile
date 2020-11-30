FROM minio/mc:latest as mc


FROM golang:latest as builder
ARG GOBIN=/usr/local/bin
ARG WAL_G_VERSION=v0.2.15

RUN apt-get update \
  && apt-get install -y git gcc liblzo2-dev cmake \
  && git clone --dept 1 -b $WAL_G_VERSION https://github.com/wal-g/wal-g $GOPATH/src/github.com/wal-g/wal-g \
  && cd $GOPATH/src/github.com/wal-g/wal-g \
  && make install \
  && make deps \
  && CGO_ENABLE=0 make pg_install


FROM postgres:13-alpine

COPY rootfs /
COPY --from=mc /usr/bin/mc /bin/mc
COPY --from=builder /usr/local/bin/wal-g  /bin/wal-g

ENV PGDATA $PGDATA/$PG_MAJOR
ENV WALG_ENVDIR /etc/wal-g.d/env

RUN mkdir -p $WALG_ENVDIR \
  && apk add --no-cache jq python3 curl \
  && curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py \
  && python3 get-pip.py \
  && rm -rf get-pip.py \
  && pip3 install envdir

CMD ["/docker-entrypoint.sh", "postgres"]
EXPOSE 5432
