#!/usr/bin/env bash

cmdname=$(basename $0)

usage()
{
    cat << USAGE >&2
Usage:
    $cmdname [-rm]
    -rm | --remove               Removes stopped containers
    -rd | --restart-docker       Restart Docker
USAGE
    exit 1
}

# process arguments
while [[ $# -gt 0 ]]
do
    case "$1" in
        -rm | --remove)
        REMOVE=1
        shift 1
        ;;
        -rd | --restart-docker)
        RESTART_DOCKER=1
        shift 1
        ;;
        --help)
        usage
        ;;
        *)
        echoerr "Unknown argument: $1"
        usage
        ;;
    esac
done

REMOVE=${REMOVE:-0}
RESTART_DOCKER=${RESTART_DOCKER:-0}

if [[ "$(docker ps -a -q 2> /dev/null)" ]]; then
    docker stop $(docker ps -a -q)

    if [[ ${REMOVE} -gt 0 ]]; then
        sudo rm -rf /var/log/*.pos
        sudo rm -rf /var/log/containers
        docker rm --force $(docker ps -a -q)
    fi
fi

if [[ ${RESTART_DOCKER} -gt 0 ]]; then
    sudo service docker restart
fi

if [[ ${REMOVE} -gt 0 ]]; then
    sudo rm -rf /var/lib/kubelet
fi
