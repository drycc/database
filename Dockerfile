FROM docker.io/minio/mc:latest as mc


FROM docker.io/library/golang:latest as builder
ARG GOBIN=/usr/local/bin
ARG WAL_G_VERSION=v0.2.19

RUN apt-get update \
  && apt-get install -y git gcc liblzo2-dev cmake \
  && git clone --dept 1 -b $WAL_G_VERSION https://github.com/wal-g/wal-g $GOPATH/src/github.com/wal-g/wal-g \
  && cd $GOPATH/src/github.com/wal-g/wal-g \
  && make install \
  && make deps \
  && make pg_install


FROM docker.io/library/postgres:13

COPY rootfs /
COPY --from=mc /usr/bin/mc /bin/mc
COPY --from=builder /usr/local/bin/wal-g  /bin/wal-g

ENV PGDATA $PGDATA/$PG_MAJOR
ENV WALG_ENVDIR /etc/wal-g.d/env

RUN mkdir -p $WALG_ENVDIR \
  && apt-get update \
  && apt-get install -y --no-install-recommends \
    jq \
    python3 \
    ca-certificates \
    python3-pip \
  && pip3 install envdir

CMD ["/docker-entrypoint.sh", "postgres"]
EXPOSE 5432
