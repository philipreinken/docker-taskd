FROM alpine:latest

ENV TASKDHOME="/home/taskd"
ENV TASKDDATA="$TASKDHOME/data"
ENV TASKDGIT="$TASKDHOME/taskd.git"
ENV TASKDPKI="$TASKDDATA/pki"
ENV BUILD_DEPENDENCIES="python git cmake make gcc g++"

RUN addgroup taskd && adduser -h $TASKDHOME -g '' -G taskd -D taskd && \
  apk upgrade -U && \
  apk add --no-cache ${BUILD_DEPENDENCIES} \
    libgcc \
    gnutls-dev \
    gnutls-utils \
    util-linux-dev \
    gettext \
    bash && \
  git clone --depth=1 https://github.com/GothenburgBitFactory/taskserver.git $TASKDGIT && \
  cd $TASKDGIT && \
  git submodule init && git submodule update && \
  cmake -DCMAKE_BUILD_TYPE=release . && \
  make && \
  cd test && make && ./run_all && cd .. && \
  make install && \
  apk del ${BUILD_DEPENDENCIES} && \
  mkdir -p $TASKDDATA && \
  cp -r $TASKDGIT/pki $TASKDPKI && \
  chown -R taskd:taskd $TASKDHOME

COPY entrypoint.sh $TASKDHOME/entrypoint.sh
COPY vars.template $TASKDPKI/vars.template

EXPOSE 53589

USER taskd

WORKDIR $TASKDDATA

ENTRYPOINT ["/home/taskd/entrypoint.sh"]
