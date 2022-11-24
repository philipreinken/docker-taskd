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
    pki_vars_override && (cd "$TASKDPKI" && ./generate >/dev/null 2>&1)
}

generate_user_cert() {
    (cd "$TASKDPKI" && ./generate.client "$1" >/dev/null 2>&1)
}

taskd_init() {
    taskd init
    create_certificates

    # Configure all generated certificates
    for cert in $TASKDPKI/*.pem; do
        cert=$(basename "$cert")
        config="${cert%.pem}"

        # In case of the api.* certificate, the config key needs to be client.*
        if [[ $cert =~ ^api ]]; then
            config="${config/#api/client}"
        fi;

        taskd config --force "$config" "$TASKDPKI/$cert"
    done;

    taskd config --force log "$TASKD_LOG"
    taskd config --force pid.file "$TASKD_PID_FILE"
    taskd config --force server "$TASKD_SERVER"

    # Display diagnostics
    taskd diagnostics
}

taskd_start() {
    if [ -n "${DEBUG:-}" ]; then
        taskd server --debug --debug.tls=2 --data "${TASKDDATA}"
    else
        taskd server --data "${TASKDDATA}"
    fi
}

taskd_add_org() {
    taskd add org "$1"
}

taskd_add_user() {
    key=$(taskd add user "$1" "$2" | awk -F ': ' '/New user key/{ print $2 }')
    filename=$(head /dev/urandom | tr -dc [:alnum:] | head -c12)

    # Generate client certificates for user
    generate_user_cert "$filename"

    printf "%-20s\t%-20s\t%-40s\t%-12s\n" "ORG" "USERNAME" "KEY" "USER-CERT"
    printf "%-20s\t%-20s\t%-40s\t%-12s\n" "$1" "$2" "$key" "$filename"
}

main() {
    if [[ ! -e "$TASKDDATA/config" ]]; then
        taskd_init
    fi

    start=1

    while [[ (($# > 0)) ]]
    do
        case "$1" in
            add-user)
                taskd_add_user "$2" "$3"
                shift 3
                start=0
                ;;
            add-org)
                taskd_add_org "$2"
                shift 2
                start=0
                ;;
            user-cert)
                cat "$TASKDPKI/$2.cert.pem"
                shift 2
                start=0
                ;;
            user-key)
                cat "$TASKDPKI/$2.key.pem"
                shift 2
                start=0
                ;;
            ca-cert)
                cat "$TASKDPKI/ca.cert.pem"
                shift
                start=0
                ;;
            *)
                shift
                ;;
          esac
    done

    if [[ (($start > 0)) ]]; then
        taskd_start
    fi
}

main "$@"
