#!/bin/bash

#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

echo "🚀 Bootstrapping the Kubernetes Local Laboratory..."

# Create the cluster using the declarative configuration file
k3d cluster create --config ../cluster/config.yaml

echo "✅ Cluster created successfully. Merging kubeconfig..."

# Merge cluster credentials into the local kubeconfig and switch context automatically
k3d kubeconfig merge platform-architect-lab --switch-context

# Verify cluster node status
echo "📊 Fetching cluster node status:"
kubectl get nodes


