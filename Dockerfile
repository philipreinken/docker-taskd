FROM ubuntu:18.04

ENV DEBIAN_FRONTEND="noninteractive"
ENV TASKDHOME="/home/taskd"
ENV TASKDDATA="$TASKDHOME/data"
ENV TASKDGIT="$TASKDHOME/taskd.git"
ENV TASKDPKI="$TASKDDATA/pki"
ENV BUILD_DEPENDENCIES="python git libgnutls28-dev uuid-dev build-essential cmake ca-certificates"

RUN useradd -m taskd && \
  apt update && apt upgrade -y && \
  apt install -y --no-install-recommends ${BUILD_DEPENDENCIES} gnutls-bin gettext-base && \
  update-ca-certificates && \
  git clone --depth=1 https://github.com/GothenburgBitFactory/taskserver.git $TASKDGIT && \
  cd $TASKDGIT && \
  git submodule init && git submodule update && \
  cmake -DCMAKE_BUILD_TYPE=release . && \
  make && \
  cd test && make && ./run_all && cd .. && \
  make install && \
  mkdir -p $TASKDDATA && \
  cp -r $TASKDGIT/pki $TASKDPKI && \
  apt remove -y --autoremove ${BUILD_DEPENDENCIES} && \
  apt-get clean && \
  chown -R taskd:taskd $TASKDHOME

COPY entrypoint.sh $TASKDHOME/entrypoint.sh
COPY vars.template $TASKDPKI/vars.template

EXPOSE 53589

USER taskd

WORKDIR $TASKDDATA

ENTRYPOINT ["/home/taskd/entrypoint.sh"]
