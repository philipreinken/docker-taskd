#!/usr/bin/env bash
set -euo pipefail

USER="user"
ORG="default"

generate_server_certs() {
  cd $TASKDCERTS && cp $TASKDGIT/pki/vars $TASKDCERTS/vars

  $TASKDGIT/pki/generate.ca >/dev/null 2>&1
  $TASKDGIT/pki/generate.server >/dev/null 2>&1
  $TASKDGIT/pki/generate.crl >/dev/null 2>&1
}

add_default_user() {
  taskd add org default >/dev/null 2>&1
  taskd add user $ORG $USER | egrep key > $TASKDCERTS/user-key
}

print_user_info() {
  echo "user: $USER"
  echo "key: $(cat $TASKDCERTS/user-key | head -n1 | awk -F': ' '{print $2}')"
  echo "group: $ORG"
  echo ""
}

init() {
  generate_server_certs
  add_default_user
  print_user_info
}

init && taskd server --data $TASKDDATA
