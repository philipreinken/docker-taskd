#!/usr/bin/env bash
set -euo pipefail

# Ensure these are set before continuing
TASKDHOME=$TASKDHOME
TASKDDATA=$TASKDDATA
TASKDGIT=$TASKDGIT
TASKDPKI=$TASKDPKI

# Config
TASKD_LOG=${TASKD_LOG:="/dev/stdout"}
TASKD_PID_FILE=${TASKD_PID_FILE:="$TASKDHOME/taskd.pid"}
TASKD_SERVER=${TASKD_SERVER:="0.0.0.0:53589"}

# Override the pki variables or fallback to default values
pki_vars_override() {
    TASKD_SEC_PARAM=${TASKD_SEC_PARAM:="high"} \
    TASKD_EXPIRATION_DAYS=${TASKD_EXPIRATION_DAYS:="365"} \
    TASKD_ORGANIZATION=${TASKD_ORGANIZATION:='"Göteborg Bit Factory"'} \
    TASKD_CN=${TASKD_CN:="localhost"} \
    TASKD_COUNTRY=${TASKD_COUNTRY:="SE"} \
    TASKD_STATE=${TASKD_STATE:='"Västra Götaland"'} \
    TASKD_LOCALITY=${TASKD_LOCALITY:='"Göteborg"'} \
    envsubst < $TASKDPKI/vars.template > $TASKDPKI/vars
}

create_certificates() {
    pki_vars_override && (cd $TASKDPKI && ./generate)
}

taskd_init() {
    taskd init
    create_certificates
    
    # Configure all generated certificates
    for cert in $TASKDPKI/*.pem; do
        cert="$(basename $cert)"
        config="${cert%.pem}"
        
        # In case of the api.* certificate, the config key needs to be client.*
        if [[ $cert =~ ^api ]]; then
            config="${config/#api/client}"
        fi;

        taskd config --force $config "$TASKDPKI/$cert"
    done;

    taskd config --force log $TASKD_LOG
    taskd config --force pid.file $TASKD_PID_FILE
    taskd config --force server $TASKD_SERVER

    # Display config
    taskd config
}

if [[ ! -e "$TASKDDATA/config" ]]; then
    taskd_init
fi

taskd server --data $TASKDDATA
