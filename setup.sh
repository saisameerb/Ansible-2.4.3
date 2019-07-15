#!/bin/bash
set -e
#TODO: Support python virtual environments for now global

# Use getopts to catch flags
install_only=0

while getopts "i" opt; do
    case "$opt" in
    i)  install_only=1 ;;
    *) echo "usage: $0 [-i]" >&2
        exit 1 ;;
    esac
done

shift $((OPTIND-1))

[ "$1" = "--" ] && shift

# Ensure path has needed directories
export PATH="/usr/local/bin:$PATH"

COLOR_END='\e[0m'
COLOR_RED='\e[0;31m'

# Install prereq packages
if [ -n "$(command -v yum)" ]; then
    sudo yum install -y git gcc python-pip python-devel libffi-devel \
        openssl-devel libxml2-devel libxslt-devel libjpeg-turbo-devel \
            zlib-devel unzip
elif [ -n "$(command -v apt-get)" ]; then
    sudo apt-get install -y git gcc python-pip python-dev libffi-dev \
        libssl-dev libxml2-dev libxslt1-dev libjpeg8-dev zlib1g-dev unzip
else
    echo "Could not identify package manager, \
        prerequisite packages may not be installed."
fi

pip install --upgrade pip

# This current directory.
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
ROOT_DIR=$(cd "$DIR/../../" && pwd)
EXTERNAL_ROLE_DIR="$ROOT_DIR/roles/external"
ROLES_REQUIREMNTS_FILE="$ROOT_DIR/roles/roles_requirements.yml"

# Exit msg
msg_exit() {
    printf "%s" "$COLOR_RED$*$COLOR_END"
    printf "\\n"
    printf "Exiting...\\n"
}

# Trap if ansible-galaxy failed and warn user
cleanup() {
    msg_exit "Update failed. Please don't commit \
    or push roles till you fix the issue"
}
trap "cleanup"  ERR INT TERM

# Check ansible-galaxy
export PATH="/usr/local/bin:$PATH"
[[ -z "$(command -v ansible-galaxy)" ]] && pip install ansible==2.4.3

# Symlink /usr/bin location to compensate for different installs
[[ -f "/usr/bin/ansible-playbook" ]] && [[ ! -f \
    /usr/local/bin/ansible-playbook ]] && sudo ln -s /usr/bin/ansible-playbook \
        /usr/local/bin/ansible-playbook

# Exit if install_only is set
if [ $install_only == 1 ]; then
    exit 0
fi

# Check roles req file
[[ ! -f "$ROLES_REQUIREMNTS_FILE" ]]  && msg_exit "roles_requirements \
    '$ROLES_REQUIREMNTS_FILE' does not exist or permssion issue.\\nPlease \
    check and rerun."

# Remove existing roles
if [ -d "$EXTERNAL_ROLE_DIR" ]; then
    cd "$EXTERNAL_ROLE_DIR"
    if [ "$(pwd)" == "$EXTERNAL_ROLE_DIR" ];then
        echo "Removing current roles in '$EXTERNAL_ROLE_DIR/*'"
        rm -rf ./*
    else
        msg_exit "Path error could not change dir to $EXTERNAL_ROLE_DIR"
    fi
fi

# Install roles
ansible-galaxy install -r "$ROLES_REQUIREMNTS_FILE" --force -p \
    "$EXTERNAL_ROLE_DIR"
