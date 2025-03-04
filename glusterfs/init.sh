#!/usr/bin/env sh

set -o nounset  # Disallow empty variables
set -o errexit  # Exit when an error occurs

# Wait for glusterd to start
service glusterd start
sleep 5  # Give it some time to initialize

# Get the current node's IP
NODE_IP=$(hostname -i)

# Fetch all active Swarm nodes (Manager + Workers)
SWARM_NODES=$(getent hosts tasks.gluster | awk '{print $1}')

echo "Gluster Node IP: $NODE_IP"
echo "Swarm Nodes: $SWARM_NODES"

# Peer probe each other
for NODE in $SWARM_NODES; do
    if [ "$NODE" != "$NODE_IP" ]; then
        gluster peer probe $NODE
    fi
done

# Ensure all nodes are connected
sleep 10
gluster peer status

# Determine the first node (only one should create the volume)
FIRST_NODE=$(echo "$SWARM_NODES" | head -n 1)

if [ "$NODE_IP" == "$FIRST_NODE" ]; then
    echo "Creating GlusterFS volume on $FIRST_NODE..."
    gluster volume create gv0 replica 3 transport tcp \
        $(echo "$SWARM_NODES" | sed 's/$/:\/data\/brick1/g' | paste -sd " " -) force
    gluster volume start gv0
fi