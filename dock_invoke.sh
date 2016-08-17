#!/bin/bash -x

# A wrapper script for invoking a py-invoke tasks script
# within a docker.

VERSION="latest"

# DATA BASE DIR
# Note: this will be mounted in /data, make sure the file
# path arguments reflext this.
DATA_DIR=/data

# DOCKER_NAME
DOCKER_NAME=dockerfile/neuro1

HOSTNAME=neurodocker

# Helper functions for guards
error(){
  error_code=$1
  echo "ERROR: $2" >&2
  echo "($PROGNAME wrapper version: $VERSION, error code: $error_code )" &>2
  exit $1
}
check_cmd_in_path(){
  cmd=$1
  which $cmd > /dev/null 2>&1 || error 1 "$cmd not found!"
}

# Guards (checks for dependencies)
check_cmd_in_path docker

# Set up mounted volumes, environment, and run our containerized command
docker run \
  --interactive --tty \
  --hostname $HOSTNAME \
  --volume "$DATA_DIR":/data \
  --volume "$PWD":/wd \
  --workdir /wd \
  "$DOCKER_NAME:$VERSION" \
  /bin/bash -c "source ~/.bashrc; $@"
