FROM ubuntu:18.04

ENV DEBIAN_FRONTEND="noninteractive"
ENV TASKDDATA="/home/taskd/data"
ENV TASKDGIT="/home/taskd/taskd.git"
ENV TASKDCERTS="$TASKDDATA/certs"
ENV BUILD_DEPENDENCIES="python git libgnutls28-dev uuid-dev build-essential cmake ca-certificates"

RUN useradd -m taskd && mkdir -p $TASKDCERTS && \
  apt update && apt upgrade -y && \
  apt install -y --no-install-recommends ${BUILD_DEPENDENCIES} gnutls-bin && \
  update-ca-certificates && \
  git clone --depth=1 https://github.com/GothenburgBitFactory/taskserver.git $TASKDGIT && \
  cd $TASKDGIT && \
  git submodule init && git submodule update && \
  cmake -DCMAKE_BUILD_TYPE=release . && \
  make && \
  cd test && make && ./run_all && cd .. && \
  make install && \
  apt remove -y --autoremove ${BUILD_DEPENDENCIES} && \
  apt-get clean && \
  chown -R taskd:taskd $TASKDDATA

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

USER taskd

EXPOSE 53589

WORKDIR $TASKDDATA

RUN taskd init && \
  taskd config server 0.0.0.0:53589 && \
  taskd config --force client.cert $TASKDCERTS/client.cert.pem && \
  taskd config --force client.key $TASKDCERTS/client.key.pem && \
  taskd config --force server.cert $TASKDCERTS/server.cert.pem && \
  taskd config --force server.key $TASKDCERTS/server.key.pem && \
  taskd config --force server.crl $TASKDCERTS/server.crl.pem && \
  taskd config --force ca.cert $TASKDCERTS/ca.cert.pem && \
  taskd config --force log /dev/stdout

ENTRYPOINT ["/entrypoint.sh"]
