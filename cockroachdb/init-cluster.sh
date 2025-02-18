#!/usr/bin/env bash

set -o nounset  # Disallow empty variables
set -o errexit  # Exit when an error occurs
# set -o xtrace   # Show executed commands

microdnf -y install jq

init_db () {
  printf 'Initializing CockroachDB...\n'
  cockroach init --insecure --host=cockroachdb:26257 # --cluster-name="bookface"
}

db_exists () {
  db_name="${1:?}"
  query="SELECT datname FROM pg_database WHERE datname = '${db_name}';"

  result="$(cockroach sql \
    --insecure \
    --format=csv \
    --execute "${query}" \
  | tail -n 1)"

  test "${result}" = "${db_name}"
}

create_db () {
  if db_exists "bf"; then
    printf 'Database already exists; skipping creation...\n'
    return 0
  fi

  printf 'Creating database...\n'

  # heredoc requires indentation with tabs
	cat <<-EOF | cockroach sql --insecure --host=cockroachdb:26257
	CREATE DATABASE IF NOT EXISTS bf;
	CREATE USER IF NOT EXISTS bfuser;
	GRANT ALL ON DATABASE bf TO bfuser;

	USE bf;
	CREATE TABLE IF NOT EXISTS users ( userID STRING(50) PRIMARY KEY DEFAULT unique_rowid(), name STRING(50), age INT, picture STRING(300), status STRING(10), bio TEXT, posts INT, stats STRING(50), comments INT, lastPostDate TIMESTAMP DEFAULT NOW(), createDate TIMESTAMP DEFAULT NOW() );
	CREATE TABLE IF NOT EXISTS posts ( postID STRING(50) PRIMARY KEY DEFAULT unique_rowid(), userID STRING(50), text TEXT, stats STRING(200), name STRING(150), image STRING(32), postDate TIMESTAMP DEFAULT NOW() );
	CREATE TABLE IF NOT EXISTS comments ( commentID STRING(50) PRIMARY KEY DEFAULT unique_rowid(), postID STRING(50), userID STRING(50), stats STRING(200), text TEXT, postDate TIMESTAMP DEFAULT NOW() );
	CREATE TABLE IF NOT EXISTS pictures ( pictureID STRING(300), stats STRING(200), picture BLOB );
	GRANT SELECT,UPDATE,INSERT on TABLE bf.* to bfuser;
	EOF
}

main () {
  while true; do
    health="$(curl -s 'http://cockroachdb:8080/health?ready=1')"
    error="$(jq -r '.error' <<< "${health}")"

    printf '%s\n' "${health}"

    # CockroachDB is shiet and returns code 14 for *all* errors
    case "${error}" in
      "node is waiting for cluster initialization")
        printf 'Initializing db...\n'
        init_db;;
      null) # Initialized :D
        printf 'Cluster ready, creating db...\n'
        create_db
        break;;
      "liveness record not found"|"node is not accepting SQL clients")
        printf 'Waiting for cluster readimness...\n';;
      *)
        printf 'Unknown message (see output above), waiting...\n';;
    esac

    sleep 2.5
  done
}

main
