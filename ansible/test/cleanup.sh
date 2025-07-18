#!/bin/bash
#
# Ansible container cleanup tool.
#
# Usage: ./cleanup.sh
#
#   - Removes all Docker containers with "ansible" in their name.
#   - Works for both running and stopped containers.

# Find all containers with "ansible" in the name (running or stopped)
containers=$(docker ps -a --filter "name=ansible" --format "{{.ID}}")

if [ -z "$containers" ]; then
  echo "No containers found."
  exit 0
fi

echo "Removing the following Ansible containers:"
docker ps -a --filter "name=ansible"

# Stop and remove them
docker rm -f $containers

echo "✅ Done."
