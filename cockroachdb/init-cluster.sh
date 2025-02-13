#!/usr/bin/env sh

set -o nounset  # Disallow empty variables
set -o errexit  # Exit when an error occurs
set -o xtrace   # Show executed commands

microdnf -y install jq

init_db () {
  printf 'Initializing CockroachDB...\n'
  cockroach init --insecure --host=cockroachdb:26357
}

db_exists () {
  db_name="${1:?}"

  result="$(cockroach sql --insecure --format=records \
      --execute "SHOW DATABASES LIKE '$db_name';" \
      | grep -c "$db_name")"

  # If 'result' > 0, we assume DB exists
  test "$result" -gt 0
}

create_db () {
  if db_exists "bf"; then
    printf 'Database already exists; skipping creation...'
    return 0
  else
    printf 'Creating database...\n'
  fi

  # heredoc requires indentation with tabs
	cat <<-EOF | cockroach sql --insecure --host=cockroachdb:26357
	CREATE DATABASE IF NOT EXISTS bf;
	CREATE USER bfuser;
	GRANT ALL ON DATABASE bf TO bfuser;
	
	USE bf;
	CREATE TABLE IF NOT EXISTS users ( userID STRING(50) PRIMARY KEY DEFAULT unique_rowid(), name STRING(50), age INT, picture STRING(300), status STRING(10), bio TEXT, posts INT, stats STRING(50), comments INT, lastPostDate TIMESTAMP DEFAULT NOW(), createDate TIMESTAMP DEFAULT NOW() );
	CREATE TABLE IF NOT EXISTS posts ( postID STRING(50) PRIMARY KEY DEFAULT unique_rowid(), userID STRING(50), text TEXT, stats STRING(200), name STRING(150), image STRING(32), postDate TIMESTAMP DEFAULT NOW() );
	CREATE TABLE IF NOT EXISTS comments ( commentID STRING(50) PRIMARY KEY DEFAULT unique_rowid(), postID STRING(50), userID STRING(50), stats STRING(200), text TEXT, postDate TIMESTAMP DEFAULT NOW() );
	CREATE TABLE IF NOT EXISTS pictures ( pictureID STRING(300), stats STRING(200), picture BLOB );
	GRANT SELECT,UPDATE,INSERT on TABLE bf.* to bfuser;
	EOF
}

wait_for_code () {
  expected_code="${1:?}"
  message="${2:-}"

  until test "$(curl -s 'http://cockroachdb:8080/health?ready=1' | jq -r '.code')" = "${expected_code}"; do
    printf '%s\n' "${message}"
    sleep 2.5
  done
}

check_db () {
  wait_for_code 14 "Waiting for CockroachDB to start..."
  init_db

  # wait_for_code "null" "Waiting for CockroachDB to be initialized..."
  # create_db
}
