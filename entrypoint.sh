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

# Export the necessary certificate vars, fall back to default values
export TASKD_SEC_PARAM=${SEC_PARAM:="high"}
export TASKD_EXPIRATION_DAYS=${EXPIRATION_DAYS:="365"}
export TASKD_ORGANIZATION=${ORGANIZATION:='"Göteborg Bit Factory"'}
export TASKD_CN=${CN:="localhost"}
export TASKD_COUNTRY=${COUNTRY:="SE"}
export TASKD_STATE=${STATE:='"Västra Götaland"'}
export TASKD_LOCALITY=${LOCALITY:='"Göteborg"'}

pki_vars_override() {
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
