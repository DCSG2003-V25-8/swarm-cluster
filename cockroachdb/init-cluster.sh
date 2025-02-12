#!/usr/bin/env sh
set -o errexit
set -o pipefail

microdnf -y install jq

until CODE="$(curl -s http://cockroachdb:8080/health?ready=1 | jq -r '.code')"; do
  printf 'Waiting for CockroachDB to start...\n'
  sleep 2
done

case "${CODE}" in
  14) # Waiting for initialization
    printf 'Initializing CockroachDB...\n'
    cockroach init --insecure --host=cockroachdb:26257;;
  null) # Already initialized
    printf 'CockroachDB already initialized, continuing...\n';;
  *) # Others
    printf "Unknown code returned from health API (%s), we're probably good to go :⁾" "${CODE}";;
esac
