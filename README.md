# *Docker Swarm Mode* Cluster

Managed by [swarm-cd](https://github.com/m-adawi/swarm-cd).\
[config/stacks.yaml](./config/stacks.yaml) contains the stacks `swarm-cd` will keep in sync.
`swarm-cd` will poll for updates every 120s (configured in [config/config.yaml](./config/config.yaml)).
Alternatively, you can test deployments with `docker stack deploy -c compose.yaml <name>`.


## Relevant commands

```bash
docker stack deploy --compose-file docker-stack.yml swarm-cd

docker service ls
docker service ps --no-trunc <ID>
docker service logs -f <ID>
docker node update --label-add tag=www www1
docker node inspect www1
docker stack rm helloworld
CFG=$RANDOM docker stack deploy -c docker-stack.yml --detach=false <NAME>
```


## Relevant links

- [Compose Deploy Specification](https://docs.docker.com/reference/compose-file/deploy/)
