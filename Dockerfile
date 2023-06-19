FROM registry.drycc.cc/drycc/base:bookworm

COPY rootfs/usr /usr/
COPY rootfs/entrypoint.sh /entrypoint.sh
ENV PYTHON_VERSION="3.11" \
  PG_MAJOR=14 \
  POSTGRESQL_VERSION="15.3"

ENV PGDATA /data/${PG_MAJOR}

RUN install-packages gcc \
  && install-stack python $PYTHON_VERSION \
  && install-stack postgresql $POSTGRESQL_VERSION \
  && . init-stack \
  && set -eux; pip3 install --disable-pip-version-check --no-cache-dir psycopg[binary] patroni[kubernetes] 2>/dev/null; set +eux \
  && apt-get purge -y --auto-remove gcc \
  && apt-get autoremove -y \
  && apt-get clean -y \
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
  && mkdir -p $PGDATA \
  && groupadd postgres && useradd -g postgres postgres \
  && chown -R postgres:postgres /data

USER postgres
ENTRYPOINT ["init-stack", "/entrypoint.sh"]
EXPOSE 5432 8008
