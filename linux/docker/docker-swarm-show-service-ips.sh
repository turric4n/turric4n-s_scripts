#!/bin/bash

# Function to get IP addresses for all services
list_services() {
    docker service ls --format "{{.Name}}" | \
    while read service_name
    do
        echo -n "$service_name: "
        task_id=$(docker service ps --filter desired-state=running --format "{{.ID}}" $service_name)

        if [ -n "$task_id" ]; then
            docker inspect --format '{{range .NetworksAttachments}}{{range .Addresses}}{{.}}{{end}}{{end}}' $task_id
        else
            echo "No running tasks"
        fi
    done
}

# Function to find a specific service by name or IP
find_service_or_ip() {
    local query=$1

    docker service ls --format "{{.Name}}" | \
    while read service_name
    do
        task_id=$(docker service ps --filter desired-state=running --format "{{.ID}}" $service_name)
        
        if [ -n "$task_id" ]; then
            ip=$(docker inspect --format '{{range .NetworksAttachments}}{{range .Addresses}}{{.}}{{end}}{{end}}' $task_id)
            if [[ $service_name == *"$query"* || $ip == *"$query"* ]]; then
                echo "$service_name: $ip"
            fi
        fi
    done
}

# Script usage
usage() {
    echo "Usage: $0 [-q <service_name_or_ip>] [-a]"
    echo "-q : Query for a specific service name or IP"
    echo "-a : List all services with their IPs"
    exit 1
}

# Main script logic
if [ $# -eq 0 ]; then
    usage
fi

while getopts ":q:a" opt; do
    case ${opt} in
        q )
            find_service_or_ip "$OPTARG"
            ;;
        a )
            list_services
            ;;
        * )
            usage
            ;;
    esac
done