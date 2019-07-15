#!/bin/bash
set -e
#TODO: Support python virtual environments for now global

export PATH="/usr/local/bin:$PATH"

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Install prereq packages
if [ -n "$(command -v yum)" ]; then
    sudo yum install -y git gcc python-pip python-devel \
    libffi-devel openssl-devel libxml2-devel libxslt-devel \
    libjpeg-turbo-devel zlib-devel unzip
elif [ -n "$(command -v apt-get)" ]; then
    sudo apt-get install -y git gcc python-pip python-dev  \
    libffi-dev libssl-dev libxml2-dev libxslt1-dev \
    libjpeg8-dev zlib1g-dev unzip
else
    echo "Could not identify package manager, \
    prerequisite packages may not be installed."
fi

# Install Ansible and other python dependencies
pip install -r "$DIR/python_requirements.txt"
pip install --upgrade pip

