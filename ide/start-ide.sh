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

  [ ! -z "$existing" ] && return

  docker build -t haskell-ide "$(getScriptDir)/docker"

  docker image prune -f
}

function createSecrets() {
  local ssh_dir="$(
    gdbmtool -r /home/docker/kvstore.db << EOF
      fetch ssh_dir
EOF
  )"

  [ -z "$ssh_dir" ] && return

  if [ ! -d "$ssh_dir" ]; then
    error "The directory $ssh_dir does not exist. SSH key secrets cannot be created as they should be."
    exit 1
  fi

  if [ ! -f "${ssh_dir}/id_rsa.pub" ]; then
    error "Cannot find the file ${ssh_dir}/id_rsa.pub. Public key secret cannot be created as it should be."
    exit 1
  fi

  if [ ! -f "${ssh_dir}/id_rsa" ]; then
    error "Cannot find the file ${ssh_dir}/id_rsa. Secret key secret cannot be created as it should be."
    exit 1
  fi

  docker secret create ssh_public_key "${ssh_dir}/id_rsa.pub"
  docker secret create ssh_secret_key "${ssh_dir}/id_rsa"
}

function getIDEContainerId() {
  echo "$(docker ps -q -f ancestor=haskell-ide)"
}

function createSwarmIfNotExists() {
  docker node ls -q 1>/dev/null 2>&1

  [ $? -eq 0 ] && return

  docker swarm init 1>/dev/null 2>&1

  createSecrets 1>/dev/null

  docker stack deploy -c "$(getScriptDir)/docker/docker-compose.yml" haskell-ide 1>/dev/null
}

function enterIDE() {
  while [ -z "$(getIDEContainerId)" ]; do sleep 1; done
  docker exec -it "$(getIDEContainerId)" screen -R
}

if ! ensureAvailableDiskSpace; then
  error "At least 12 giga-bytes are necessary to build the environment."
  error "Please add storage to your machine then restart it with run vagrant up --provision"
  error "Make sure the DOCKER_VOLUME_AUTO_EXTEND variable is set to 1 in your .env file."

  exit 1
fi

buildDockerImageIfNotExists
createSwarmIfNotExists
enterIDE