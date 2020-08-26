FROM postgres:13-alpine

COPY rootfs /

ENV PGDATA $PGDATA/$PG_MAJOR
ENV WALG_ENVDIR /etc/wal-g.d/env
ADD https://github.com/wal-g/wal-g/releases/download/v0.2.16/wal-g.linux-amd64.tar.gz /bin

RUN wget https://dl.min.io/client/mc/release/linux-amd64/mc -O /bin/mc \
  && chmod +x /bin/mc \
  && mkdir -p $WALG_ENVDIR \
  && tar -xvzf /bin/wal-g.linux-amd64.tar.gz -C /bin && rm /bin/wal-g.linux-amd64.tar.gz \
  && wget https://github.com/sgerrand/alpine-pkg-glibc/releases/download/2.31-r0/glibc-2.31-r0.apk \
  && apk add --allow-untrusted glibc-2.31-r0.apk \
  && rm glibc-2.31-r0.apk \
  && apk add --no-cache jq python3 curl \
  && curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py \
  && python3 get-pip.py \
  && rm -rf get-pip.py \
  && pip3 install envdir

CMD ["/docker-entrypoint.sh", "postgres"]
EXPOSE 5432
