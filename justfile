# vi: ft=make

# Just quick reference: https://github.com/casey/just/blob/master/examples/kitchen-sink.just

set dotenv-load
set export

dir := absolute_path(justfile_directory())

@_help:
  just -l

_pull:
  git pull

# Deploy a stack
[group('stack')]
deploy SERVICE: _pull
  {{ if path_exists(join(dir, SERVICE)) == "true" { "" } else { error("Invalid service " + SERVICE) } }}

  CFG="$(shuf -i 0-255 -n 1)" \
  docker stack deploy \
    --compose-file='{{join(dir, SERVICE, "docker-stack.yml")}}' \
    --detach=false \
    --resolve-image=always \
    --with-registry-auth \
    "{{SERVICE}}"

# Source env file:
# @set -o allexport; \
#   test -f '{{join(dir, SERVICE, ".env")}}' \
#     && source '{{join(dir, SERVICE, ".env")}}'; \
#   set +o allexport; \

# Delete stack
[confirm('Are you sure? (y/N)')]
[group('stack')]
rm SERVICE:
  docker stack rm "{{SERVICE}}"

# List available stacks
[group('stack')]
@ls:
  printf 'Available stacks/services:\n'
  find . \
    -mindepth 2 \
    -type f \
    -name "docker-stack.y*ml" \
    -exec sh -c 'printf "    "; basename "$(dirname "{}")"' \; \
  | sort -u

# List running services
[group('stack')]
@ps:
  printf 'Running services:\n'
  docker service ls | awk '{ printf "\t%s\t\t%s\t%s\n", $1, $4, $2 }'

# Show logs for a service
[group('stack')]
logs SERVICE N="1":
  docker service logs -f \
    "$(docker stack ps "{{SERVICE}}" | grep Running | awk 'NR=={{N}}' | awk '{print $1}')")"
