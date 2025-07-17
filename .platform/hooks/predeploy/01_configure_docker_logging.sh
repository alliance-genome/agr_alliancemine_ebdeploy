#!/bin/bash
# Configure Docker to preserve local logging while docker-compose handles GELF
# This approach maintains EB log integration and provides a fallback

set -e

echo "Configuring Docker logging..."

# Check if daemon.json exists and has unwanted log-driver config
if [ -f /etc/docker/daemon.json ]; then
    # Parse the file and check for log-driver
    if jq -e '.["log-driver"]' /etc/docker/daemon.json >/dev/null 2>&1; then
        echo "Found log-driver in daemon.json, removing it to allow compose configuration"
        
        # Remove only the log-driver and log-opts keys, preserve other settings
        jq 'del(.["log-driver"]) | del(.["log-opts"])' /etc/docker/daemon.json > /tmp/daemon.json.new
        
        # Only update if the file actually changed
        if ! cmp -s /etc/docker/daemon.json /tmp/daemon.json.new; then
            cp /tmp/daemon.json.new /etc/docker/daemon.json
            echo "Updated daemon.json, restarting Docker..."
            systemctl restart docker
            
            # Wait for Docker to be ready
            for i in {1..30}; do
                if docker info >/dev/null 2>&1; then
                    echo "Docker restarted successfully"
                    break
                fi
                sleep 1
            done
        else
            echo "No changes needed to daemon.json"
        fi
        
        rm -f /tmp/daemon.json.new
    fi
fi

echo "Docker logging configuration complete"