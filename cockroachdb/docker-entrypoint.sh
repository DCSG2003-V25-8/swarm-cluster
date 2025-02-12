#!/usr/bin/env sh

set -o nounset  # Disallow empty variables
set -o errexit  # Exit when an error occurs
set -o monitor  # Needed for job control

SWARM_ID="${SWARM_ID:?}"
SWARM_HOSTNAME="${SWARM_HOSTNAME:?}"
HEALTH_API="http://localhost:8080/health?ready=1"

echo $SWARM_ID at $SWARM_HOSTNAME
tail -f /dev/null

printf 'Starting CockroachDB instance %s...\n' "${SWARM_ID}"

printf 'Starting CockroachDB in background...\n'
# TODO Advertise as hostname (--advertise-addr)
cockroach start \
  --insecure \
  --advertise-addr="${SWARM_HOSTNAME}:26257" \
  --join="tasks.cockroachdb:26257" \
  --http-addr="0.0.0.0:8080" \
  --cache="25%" \
  --max-sql-memory="25%" &

init_cockroach () {
  cockroach init --insecure --host="0.0.0.0:26257"
  # NOTE heredoc requires indentation with tabs
	cat <<-EOF | cockroach sql --insecure --host=0.0.0.0:26257
	CREATE DATABASE IF NOT EXISTS bf;
	CREATE USER bfuser;
	GRANT ALL ON DATABASE bf TO bfuser;
	
	USE bf;
	CREATE TABLE IF NOT EXISTS users ( userID STRING(50) PRIMARY KEY DEFAULT unique_rowid(), name STRING(50), age INT, picture STRING(300), status STRING(10), bio TEXT, posts INT, stats STRING(50), comments INT, lastPostDate TIMESTAMP DEFAULT NOW(), createDate TIMESTAMP DEFAULT NOW());
	CREATE TABLE IF NOT EXISTS posts ( postID STRING(50) PRIMARY KEY DEFAULT unique_rowid(), userID STRING(50),text TEXT, stats STRING(200), name STRING(150), image STRING(32), postDate TIMESTAMP DEFAULT NOW());
	CREATE TABLE IF NOT EXISTS comments ( commentID STRING(50) PRIMARY KEY DEFAULT unique_rowid(), postID STRING(50), userID STRING(50), stats STRING(200), text TEXT,  postDate TIMESTAMP DEFAULT NOW());
	CREATE TABLE IF NOT EXISTS pictures ( pictureID STRING(300), stats STRING(200), picture BLOB );
	GRANT SELECT,UPDATE,INSERT on TABLE bf.* to bfuser;
	EOF
}

if test "${SWARM_ID}" -eq "1"; then
  curl -sLo jq 'https://github.com/jqlang/jq/releases/download/jq-1.7.1/jq-linux-amd64'
  chmod +x ./jq

  while true; do
    CODE="$(curl -s "${HEALTH_API}" | ./jq '.code')"

    case "${CODE}" in
      14) # Waiting for initialization
        printf 'Initializing CockroachDB...\n'
        init_cockroach
        break;;
      null) # Already initialized
        printf 'CockroachDB already initialized, continuing...\n'
        break;;
      *) # Others
        printf 'Unknown code returned from health API: %s. Retrying in 5 seconds...\n' "${CODE}"
        sleep 5;;
    esac
  done

  printf 'Initialization complete...\n'
fi

printf 'Restoring CockroachDB to foreground...\n'
fg
