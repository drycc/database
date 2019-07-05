FROM minio/mc:RELEASE.2019-05-23T01-33-27Z as mc

FROM postgres:11-alpine

COPY rootfs /
COPY --from=mc /usr/bin/mc /bin/mc

ENV PGDATA $PGDATA/$PG_MAJOR
ENV WALG_ENVDIR /etc/wal-g.d/env
ADD https://github.com/wal-g/wal-g/releases/download/v0.2.9/wal-g.linux-amd64.tar.gz /bin

RUN mkdir -p $WALG_ENVDIR \
  && tar -xvzf /bin/wal-g.linux-amd64.tar.gz -C /bin && rm /bin/wal-g.linux-amd64.tar.gz \
  && wget https://github.com/sgerrand/alpine-pkg-glibc/releases/download/2.28-r0/glibc-2.28-r0.apk \
    && apk add --allow-untrusted glibc-2.28-r0.apk \
    && rm glibc-2.28-r0.apk \
  && apk add --no-cache jq python3 \
  && pip3 install --upgrade pip setuptools \
  && pip install envdir

CMD ["/docker-entrypoint.sh", "postgres"]
EXPOSE 5432
