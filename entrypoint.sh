#!/bin/sh

# Default to uvicorn if K3S_ROLE is not set
if [ -z "$K3S_ROLE" ]; then
    echo "Starting Uvicorn application..."
    exec uvicorn main:app --host "0.0.0.0" --port "$PORT" --workers 1

# Start as K3s Server (Control Plane)
elif [ "$K3S_ROLE" = "server" ]; then
    echo "Starting K3s Server..."
    # --cluster-init starts the first server in a new cluster
    # --data-dir=/data ensures K3s stores data in a persistent location if mounted
    /usr/local/bin/k3s server --cluster-init --data-dir=/data &

    # Wait for the server to initialize and print the Kubeconfig for retrieval
    # CRITICAL: You must manually grab this output from the Railway console logs
    sleep 20
    if [ -f /etc/rancher/k3s/k3s.yaml ]; then
      echo "--- KUBECONFIG START ---"
      cat /etc/rancher/k3s/k3s.yaml
      echo "--- KUBECONFIG END ---"
    fi

# Start as K3s Agent (Worker Node)
elif [ "$K3S_ROLE" = "agent" ]; then
    if [ -z "$K3S_URL" ] || [ -z "$K3S_TOKEN" ]; then
        echo "Error: K3S_URL and K3S_TOKEN must be set for agent role."
        exit 1
    fi
    echo "Starting K3s Agent and joining cluster at $K3S_URL..."
    # --server and --token variables are read from Railway environment variables
    /usr/local/bin/k3s agent --server "$K3S_URL" --token "$K3S_TOKEN" --data-dir=/data

else
    echo "Error: Invalid K3S_ROLE set. Must be 'server', 'agent', or empty."
    exit 1
fi

# Keep the shell running to prevent the container from exiting
wait