# Docker Swarm Mode Cluster

## Relevant commands

```bash
docker stack deploy --compose-file docker-compose.yaml swarm-cd

docker service ls
docker service ps <ID>
docker service logs -f <ID>
docker node update --label-add tag=www www1
docker node inspect www1
docker stack rm helloworld
```
