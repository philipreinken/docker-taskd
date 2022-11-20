FROM alpine:latest

ARG TASKD_COMMIT="1.2.0"

ENV TASKDHOME="/home/taskd"
ENV TASKDDATA="$TASKDHOME/data"
ENV TASKDGIT="$TASKDHOME/taskd.git"
ENV TASKDPKI="$TASKDDATA/pki"

RUN addgroup taskd && adduser -h $TASKDHOME -g '' -G taskd -D taskd && \
  apk upgrade -U && \
  apk add --no-cache --virtual=taskd-build-dependencies \
    python3 \
    git \
    cmake \
    make \
    gcc \
    g++ && \
  apk add --no-cache \
    libgcc \
    gnutls-dev \
    gnutls-utils \
    util-linux-dev \
    gettext \
    bash && \
  ln -sf $(which python3) /usr/local/bin/python && \
  git clone https://github.com/GothenburgBitFactory/taskserver.git $TASKDGIT && \
  cd $TASKDGIT && \
  git checkout $COMMIT && \
  git submodule init && git submodule update && \
  cmake -DCMAKE_BUILD_TYPE=release . && \
  make && \
  cd test && make && ./run_all && cd .. && \
  make install && \
  apk del taskd-build-dependencies && \
  mkdir -p $TASKDDATA && \
  cp -r $TASKDGIT/pki $TASKDPKI && \
  chown -R taskd:taskd $TASKDHOME

COPY entrypoint.sh $TASKDHOME/entrypoint.sh
COPY vars.template $TASKDPKI/vars.template

EXPOSE 53589

USER taskd

WORKDIR $TASKDDATA

ENTRYPOINT ["/home/taskd/entrypoint.sh"]
