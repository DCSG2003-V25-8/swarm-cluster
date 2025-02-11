# vi: ft=make

default: _help

@_help:
  just -l

pull:
  git pull

deploy SERVICE: pull
  docker stack deploy --compose-file=./{{SERVICE}}/docker-stack.yml --detach=false --resolve-image=always --with-registry-auth {{SERVICE}}

rm SERVICE:
  docker stack rm {{SERVICE}}

logs SERVICE N="1":
  #!/usr/bin/env bash
  set -euxo pipefail
  id="$(docker stack ps {{SERVICE}} | grep Running | awk 'NR=={{N}}' | awk '{print $1}')"
  docker service logs -f "${id}"
