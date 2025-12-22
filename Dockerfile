ARG CODENAME
FROM registry.drycc.cc/drycc/base:${CODENAME}

COPY rootfs/usr /usr/
COPY rootfs/entrypoint.sh /entrypoint.sh


ARG PYTHON_VERSION="3.13" \
  POSTGRES_EXPORTER_VERSION="0.18.1"

ENV HOME=/data \
  PG_MAJOR=18 \
  PG_MINOR=1 \
  S3_RCLONE_VERSION="1.71.1" 

ENV PGDATA=$HOME/$PG_MAJOR

RUN install-packages vim gcc pigz jq\
  && install-stack python $PYTHON_VERSION \
  && install-stack postgresql $PG_MAJOR.$PG_MINOR \
  && install-stack rclone $S3_RCLONE_VERSION \
  && install-stack postgres_exporter $POSTGRES_EXPORTER_VERSION \
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
  && chown -R postgres:postgres $HOME

USER postgres
ENTRYPOINT ["init-stack", "/entrypoint.sh"]
EXPOSE 5432 8008
