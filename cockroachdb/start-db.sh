#!/usr/bin/env sh

set -o nounset  # Disallow empty variables
set -o errexit  # Exit when an error occurs

cockroach start \
  --insecure \
  --join=tasks.cockroachdb:26357 \
  --advertise-addr="$(hostname -f):26357" \
  --listen-addr="$(hostname -f):26357" \
  --http-addr="$(hostname -f):8080" \
  --sql-addr="$(hostname -f):26257"
  # --cache=25% \
  # --max-sql-memory=25%
