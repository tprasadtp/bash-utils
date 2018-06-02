#!/usr/bin/env bash

# This is a bash utility to test the script in docker container
# Version:1.0
# Author: Prasad Tengse
# Licence: GPLv3
# Github Repository: https://github.com/tprasadtp/after-effects-ubuntu

set -o pipefail
branch=master
if [ "$TRAVIS_EVENT_TYPE" == "pull_request" ];then
  branch="$TRAVIS_PULL_REQUEST_BRANCH"
elif [ "$TRAVIS_EVENT_TYPE" == "push" ]; then
  branch="$TRAVIS_BRANCH"
elif [ "$TRAVIS_EVENT_TYPE" == "cron" ] || [ "$TRAVIS_EVENT_TYPE" == "api" ] ; then
  branch="$TRAVIS_BRANCH"
fi
function main()
{
  dir=$(cd -P -- "$(dirname -- "$0")" && pwd -P)
  #shellcheck disable=SC2116
  dir=$(echo "${dir/tests/}")
  log_file="$dir"/after-effects-logs/after-effects.log
  # set eo on script.
  sed -i 's/set -o pipefail/set -eo pipefail/g' "$dir"/after-effects
  echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
  echo "Building Stretch Docker Image"
  docker build -t  ubuntu:ae-stretch ./dockerfiles/stretch
  echo "Adding Xenial and above list to app-list.list"
  echo "./data/xenial-above.list" >> ./data/app-list.list
  echo "Removing Utils"
  sed -i '/data\/utilities.list/d' ./data/app-list.list
  echo "Adding External Repos"
  echo "./data/extern-repo.list" >> ./data/app-list.list
  echo "Removing Timeshift"
  sed -i '/timeshift/d' ./data/extern-repo.list
  echo "Running in Docker Debian Stretch"

  docker run -it -e TRAVIS="$TRAVIS" \
  --hostname=Docker-Stretch \
  -v "$(pwd)":/shared \
  ubuntu:ae-stretch \
  ./after-effects --fix --simulate --yes --enable-pre --enable-post --api-endpoint https://"${branch}"--ubuntu-post-install.netlify.com/cfg

  exit_code_from_container="$?"
  echo "Exit code from docker run is: $exit_code_from_container"
  echo "Print Logs is set to: $PRINT_LOGS"
  if [ "$PRINT_LOGS" == "true" ] || [[ "$exit_code_from_container" -gt 0 ]]; then
    echo " "
    echo " "
    echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
    cat "$log_file"
  fi

  return "$exit_code_from_container"
}

main "$@"