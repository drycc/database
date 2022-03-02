FROM docker.io/drycc/base:bullseye

ENV PGDATA /opt/drycc/postgresql/14/data
ENV WALG_ENVDIR /etc/wal-g.d/env

COPY rootfs/bin /bin/
COPY rootfs/docker-entrypoint-initdb.d /docker-entrypoint-initdb.d/
COPY rootfs/docker-entrypoint.sh /docker-entrypoint.sh
ENV JQ_VERSION="1.6" \
  GOSU_VERSION="1.14" \
  MC_VERSION="RELEASE.2022-02-26T03-58-31Z" \
  WAL_G_VERSION="1.1" \
  PYTHON_VERSION="3.10.2" \
  POSTGRESQL_VERSION="14.2"

RUN mkdir -p $WALG_ENVDIR \
  && install-stack jq $JQ_VERSION \
  && install-stack gosu $GOSU_VERSION \
  && install-stack mc $MC_VERSION \
  && install-stack wal-g $WAL_G_VERSION \
  && install-stack python $PYTHON_VERSION \
  && install-stack postgresql $POSTGRESQL_VERSION && . init-stack \
  && rm -rf \
      /usr/share/doc \
      /usr/share/man \
      /usr/share/info \
      /usr/share/locale \
      /var/lib/apt/lists/* \
      /var/log/* \
      /var/cache/debconf/* \
      /etc/systemd \
      /lib/lsb \
      /lib/udev \
      /usr/lib/`echo $(uname -m)`-linux-gnu/gconv/IBM* \
      /usr/lib/`echo $(uname -m)`-linux-gnu/gconv/EBC* \
  && mkdir -p /usr/share/man/man{1..8} \
  && mkdir -p /run/postgresql $PGDATA \
  && groupadd postgres && useradd -g postgres postgres \
  && chown -R postgres:postgres /run/postgresql $PGDATA \
  && set -eux; pip3 install --disable-pip-version-check --no-cache-dir envdir 2>/dev/null

ENTRYPOINT ["init-stack"]
CMD ["/docker-entrypoint.sh", "postgres"]
EXPOSE 5432
