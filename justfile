# vi: ft=make

# Just quick reference: https://github.com/casey/just/blob/master/examples/kitchen-sink.just

set dotenv-load
set dotenv-required
set export

dir := absolute_path(justfile_directory())

[group('util')]
@_default:
  just --list

[group('util')]
@_is_service SERVICE:
  {{ if path_exists(join(dir, SERVICE)) == "true" { "" } else { error("Invalid service " + SERVICE) } }}

# Deploy a stack
[group('stack')]
deploy SERVICE: (_is_service SERVICE)
  CFG="$(date +%s)" \
  docker stack deploy \
    --compose-file='{{join(dir, SERVICE, "docker-stack.yml")}}' \
    --detach=false \
    --resolve-image=always \
    --with-registry-auth \
    "{{SERVICE}}"

# Delete stack
[confirm('Are you sure? (y/N)')]
[group('stack')]
rm SERVICE: (_is_service SERVICE)
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

# Show logs for a service (`N`: container no.)
[group('stack')]
logs SERVICE N="1": (_is_service SERVICE)
  docker service logs -f \
    "$(docker stack ps "{{SERVICE}}" | grep Running | awk 'NR=={{N}}' | awk '{print $1}')"
