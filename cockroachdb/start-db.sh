#!/usr/bin/env sh

set -o nounset  # Disallow empty variables
set -o errexit  # Exit when an error occurs
# set -o xtrace   # Show executed commands

microdnf -y install bind-utils

nodes="$(dig tasks.cockroachdb +short | sed 's/$/:26257/' | paste -sd, -)"

cockroach start \
  --insecure \
  --listen-addr="0.0.0.0:26257" \
  --http-addr="0.0.0.0:8080" \
  --advertise-addr="$(hostname -i):26257" \
  --join="${nodes}" # \
  # --cluster-name="bookface"
  # --cluster-name="bookface" \
  # --join=tasks.cockroachdb:26257 \
  # --listen-addr=":26257" \
  # --sql-addr=":26257" \
  # --advertise-addr="$(hostname -i):26257"
  # --advertise-addr="cockroachdb:26257" \
  # --listen-addr="0.0.0.0:26257" \
  # --http-addr="0.0.0.0:8080" \
  # --sql-addr="0.0.0.0:26257"
  # --cache=25% \
  # --max-sql-memory=25%
