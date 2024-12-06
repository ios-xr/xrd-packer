#!/bin/bash

function delete_default_routes_except() {
    local exclude_gateway=$1

    # List all default routes
    default_routes=$(ip route | grep '^default')

    if [ -z "$default_routes" ]; then
        return
    fi

    # Loop through and delete each default route except the specified gateway
    while IFS= read -r route; do
        # Extract the gateway IP from the route
        gateway=$(echo $route | awk '{print $3}')

        if [ "$gateway" != "$exclude_gateway" ]; then
            # Delete the default route
            sudo ip route del default via $gateway
        else
            echo "Skipping deletion of route via $exclude_gateway"
        fi
    done <<< "$default_routes"

}

# Main script execution
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <gateway_to_exclude>"
    echo "Example: $0 192.168.1.1"
    exit 1
fi

exclude_gateway=$1

delete_default_routes_except "$exclude_gateway"