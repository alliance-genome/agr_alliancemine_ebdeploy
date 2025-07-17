#!/bin/bash
# Configure Docker to preserve local logging while docker-compose handles GELF
# This approach maintains EB log integration and provides a fallback
#
# This runs as a predeploy hook to ensure Docker is configured before containers start.
# Uses 'systemctl reload docker' (SIGHUP) which safely reloads daemon.json without
# stopping containers - critical for containers with restart policy "no".

set -euo pipefail

echo "[docker-log-hook] Starting Docker logging configuration..."

# Ensure jq is installed (required for JSON manipulation)
if ! command -v jq &> /dev/null; then
    echo "[docker-log-hook] jq not found, installing..."
    if ! yum install -y jq; then
        echo "[docker-log-hook] ERROR: Failed to install jq. Exiting gracefully to allow deployment to continue."
        exit 0  # Exit gracefully to not block deployment
    fi
fi

# Create secure temporary file with automatic cleanup
TMP_FILE=$(mktemp)
trap 'rm -f "$TMP_FILE"' EXIT

# Check if daemon.json exists and has unwanted log-driver config
if [ -f /etc/docker/daemon.json ]; then
    # Check if either log-driver or log-opts exists
    if jq -e 'has("log-driver") or has("log-opts")' /etc/docker/daemon.json >/dev/null 2>&1; then
        echo "[docker-log-hook] Found logging configuration in daemon.json, removing it..."
        
        # Remove both log-driver and log-opts keys, preserve other settings
        jq 'del(.["log-driver"]) | del(.["log-opts"])' /etc/docker/daemon.json > "$TMP_FILE"
        
        # Validate the generated JSON
        if ! jq -e . >/dev/null 2>&1 < "$TMP_FILE"; then
            echo "[docker-log-hook] ERROR: JSON transformation produced invalid JSON. Aborting." >&2
            exit 1
        fi
        
        # Only update if the file actually changed
        if ! cmp -s /etc/docker/daemon.json "$TMP_FILE"; then
            # Use atomic file replacement to prevent corruption
            install -m 644 "$TMP_FILE" /etc/docker/daemon.json.new
            mv -f /etc/docker/daemon.json.new /etc/docker/daemon.json
            echo "[docker-log-hook] Updated daemon.json"
            
            # Reload Docker to apply configuration changes
            if systemctl is-active --quiet docker; then
                echo "[docker-log-hook] Reloading Docker configuration (SIGHUP)..."
                # Use reload which sends SIGHUP - this is safe and won't stop containers
                if ! systemctl reload docker; then
                    echo "[docker-log-hook] ERROR: Failed to reload Docker configuration" >&2
                    exit 1
                fi
                echo "[docker-log-hook] Docker configuration reloaded successfully"
                echo "[docker-log-hook] Note: Logging changes apply to new containers only"
            else
                echo "[docker-log-hook] Docker is not running, skipping reload"
            fi
        else
            echo "[docker-log-hook] No changes needed to daemon.json"
        fi
    else
        echo "[docker-log-hook] No logging configuration found in daemon.json"
    fi
else
    echo "[docker-log-hook] No daemon.json file found"
fi

echo "[docker-log-hook] Docker logging configuration complete"