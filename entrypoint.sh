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

cut_shasum() {
    echo -n "$1" | sha256sum - | awk '{ print $1 }' | cut -c-12 -
}

generate_user_cert() {
    (cd "$TASKDPKI" && ./generate.client "$1" >/dev/null 2>&1)
}

print_user_cert() {
    cert_file_sha=$(cut_shasum "$1")
    cat "$TASKDPKI/$cert_file_sha.cert.pem"
}

print_user_key() {
    key_file_sha=$(cut_shasum "$1")
    cat "$TASKDPKI/$key_file_sha.key.pem"
}

print_ca_cert() {
    cat "$TASKDPKI/ca.cert.pem"
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
    taskd server --data "$TASKDDATA"
}

taskd_add_org() {
    taskd add org "$1"
}

taskd_add_user() {
    key=$(taskd add user "$1" "$2" | awk -F ': ' '/New user key/{ print $2 }')
    filename=$(cut_shasum "$2")

    # Generate client certificates for user
    generate_user_cert "$filename"

    printf "%-15s\t%-25s\t%-40s\n" "ORG" "USERNAME" "KEY"
    printf "%-15s\t%-25s\t%-40s\n" "$1" "$2" "$key"
}

main() {
    if [[ ! -e "$TASKDDATA/config" ]]; then
        taskd_init
    fi

    start=1

    while [[ (($# > 0)) ]]
    do
        case "$1" in
            -a|--add-user)
                taskd_add_user "$2" "$3"
                shift 3
                start=0
                ;;
            -o|--add-org)
                taskd_add_org "$2"
                shift 2
                start=0
                ;;
            --user-cert)
                print_user_cert "$2"
                shift 2
                start=0
                ;;
            --user-key)
                print_user_key "$2"
                shift 2
                start=0
                ;;
            --ca-cert)
                print_ca_cert
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
