#!/bin/sh

function getScriptDir() {
  local scriptFile="$(echo "$0" | awk -v pwd="$(pwd -P)" -e '{ if( substr( $0, 1, 1 ) != "/" ) { print pwd"/"$0 } else print $0 }')"

  local resolvedScriptFile=
  if [ -L "$scriptFile" ]; then
    resolvedScriptFile="$(readlink "$scriptFile")"
  else
    resolvedScriptFile="$scriptFile"
  fi

  cd "$(dirname "$resolvedScriptFile")"

  local scriptDir="$(pwd -P)"

  cd - 1>/dev/null 2>&1

  echo "$scriptDir"
}

function error() {
  echo "$@" 1>&2
}

function ensureAvailableDiskSpace() {
  df -h | awk -e 'BEGIN { FS=" " } $6 ~ /\/var\/lib\/docker/ { gsub( /G/, "", $4 ); if( $4 + 0.0 < 12 ) exit 1 }'
}

function buildDockerImageIfNotExists(){
  local existing="$(docker image ls -q --filter=reference=haskell-ide:latest --filter=label=role=haskell-ide --filter=label=maintainer=MetaBarj0)"

  [ ! -z "$existing" ] && return 0

  if ! ensureAvailableDiskSpace; then
    error "At least 12 giga-bytes are necessary to build the environment."
    error "Please add storage to your machine then restart it with run vagrant up --provision"
    error "Make sure the DOCKER_VOLUME_AUTO_EXTEND variable is set to 1 in your .env file."
    error "If the build fails due to lack of storage space, extend it then it will resume at the last point it failed."
  fi

  docker build -t haskell-ide "$(getScriptDir)/docker"

  if [ $? -ne 0 ]; then
    return 1
  fi

  local orphanContainers="$(docker ps -aq)"

  if [ ! -z "$orphanContainers" ]; then
    docker rm "$orphanContainers"
  fi

  docker image prune -f
}

function createExternalSecrets() {
  local ssh_dir="$(
    gdbmtool -r /home/docker/kvstore.db << EOF
      fetch ssh_dir
EOF
  )"

  [ -z "$ssh_dir" ] && return 1

  if [ ! -d "$ssh_dir" ]; then
    error "The directory $ssh_dir does not exist. SSH key secrets cannot be created as they should be."
    return 1
  fi

  if [ ! -f "${ssh_dir}/id_rsa.pub" ]; then
    error "Cannot find the file ${ssh_dir}/id_rsa.pub. Public key secret cannot be created as it should be."
    return 1
  fi

  if [ ! -f "${ssh_dir}/id_rsa" ]; then
    error "Cannot find the file ${ssh_dir}/id_rsa. Secret key secret cannot be created as it should be."
    return 1
  fi

  docker secret create haskell-ide_ssh_public_key "${ssh_dir}/id_rsa.pub" \
    && docker secret create haskell-ide_ssh_secret_key "${ssh_dir}/id_rsa"
}

function getIDEContainerId() {
  echo "$(docker ps -q -f ancestor=haskell-ide)"
}

function getHealthyIDEContainerId() {
  echo "$(docker ps -q -f health=healthy)"
}

function deployStack() {
  docker stack deploy \
    --with-registry-auth \
    -c "$(getScriptDir)/docker/docker-compose.yml" \
    haskell-ide 1>/dev/null 2>&1
}

function isStackExisting() {
  docker stack ls 2>/dev/null | grep -q haskell-ide
}

function resetStackIfNeeded() {
  if ! isStackExisting; then
    return 0
  fi

  local resetAsked="$(
    gdbmtool -r /home/docker/kvstore.db << EOF 2>/dev/null
      fetch reset_stack_on_provision
EOF
  )"

  [ -z "$resetAsked" ] && return 0
  [ "$resetAsked" == '0' ] && return 0

  local value="$(echo $resetAsked | tr [:lower:] [:upper:])"
  [ "$value" == 'FALSE' ] && return 0

  echo "Resetting haskell-ide service..."
  docker swarm leave -f 1>/dev/null 2>&1 \
    && gdbmtool /home/docker/kvstore.db << EOF
      delete reset_stack_on_provision
EOF

  # these lines deserve an explanation: Once the swarm is dead after the docker
  # swarm leave -f command execution, sometimes remains an orphan node that
  # prevent the creation of a new swarm.
  # To see it, I have to wait an arbitrary amount of time, it's really ugly.
  # I've not find a better workarount to fix that, maybe I should report such a
  # behavior...
  sleep 5
  if [ "$(docker node ls -q 2>/dev/null | wc -l)" -ne 0 ]; then
    docker swarm leave -f
  fi
}

function createSwarmIfNotExists() {
  if isStackExisting; then
    return 0
  fi

  docker swarm init --force-new-cluster 1>/dev/null 2>&1

  createExternalSecrets 1>/dev/null

  if ! deployStack; then
    error "Error while deploying/resetting the docker stack."
    return 1
  fi
}

function enterIDE() {
  echo "Starting haskell-ide service..."
  while [ -z "$(getIDEContainerId)" ]; do sleep 1; done

  echo "Configuring haskell-ide service..."
  while [ -z "$(getHealthyIDEContainerId)" ]; do sleep 1; done

  docker exec -it "$(getIDEContainerId)" screen -R
}

buildDockerImageIfNotExists \
  && resetStackIfNeeded \
  && createSwarmIfNotExists \
  && enterIDE