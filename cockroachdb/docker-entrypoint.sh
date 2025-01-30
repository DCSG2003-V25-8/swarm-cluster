#!/usr/bin/env sh

set -o nounset  # Disallow empty variables
set -o errexit  # Exit when an error occurs
set -o monitor  # Needed for job control
set -o pipefail # Fail if any fail occurs in pipe

SWARM_ID="${SWARM_ID:?}"
HEALTH_API="http://localhost:8080/health?ready=1"

printf 'Starting CockroachDB instance %s...\n' "${SWARM_ID}"

printf 'Starting CockroachDB in background...\n'
./cockroach start \
  --insecure \
  # TODO Advertise as hostname
  --advertise-addr="0.0.0.0:26257" \
  --join="tasks.cockroachdb:26257" \
  --http-addr="0.0.0.0:8080" \
  --cache="25%" \
  --max-sql-memory="25%" &

if test "${SWARM_ID}" -eq "1"; then
  curl -sLo jq 'https://github.com/jqlang/jq/releases/download/jq-1.7.1/jq-linux-amd64'
  chmod +x ./jq

  while true; do
    CODE="$(curl -s "${HEALTH_API}" | ./jq '.code')"

    case "${CODE}" in
      14) # Waiting for initialization
        printf 'Initializing CockroachDB...\n'
        ./cockroach init --insecure --host="localhost:26257";;
      null) # Already initialized
        printf 'CockroachDB already initialized, continuing...\n';;
      *) # Others
        printf 'Unknown code returned from health API: %s. Retrying in 5 seconds...\n' "${CODE}"
	sleep 5
	continue;;
    esac

    break
  done

  printf 'Initialization complete...\n'
fi

printf 'Restoring CockroachDB to foreground...\n'
fg
