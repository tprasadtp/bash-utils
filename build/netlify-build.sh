#!/usr/bin/env bash
#shellcheck disable=SC2059

# This is a bash script to build jekyll website and test it with htmlproofer
# Netlify Deployments
# Version:1.0
# Author: Prasad Tengse

# gh-pages is built on travis. and deploy it on netlify to production.
# Remove .toml and scripts. & deploy the entire branch. No need to build anything as its already built.
# If something else is pushed to any branches, deploy it as branch deploy.
set -e # halt script on error
DEPLOY_PARAM_JSON=./_site/deploy.json

echo "---> Building Website "

function gen_metadata()
{
echo "---> Generating Deploy Params "
cat <<EOT > "${DEPLOY_PARAM_JSON}"
{
  "commit": {
    "id": "${COMMIT_REF:0:7}",
    "branch": "${BRANCH:-NA}",
    "pr": "${PULL_REQUEST:-false}"
  },
  "build": {
    "builder": "netlify",
    "context": "${CONTEXT:-NA}",
    "delploy_url": "${DEPLOY_URL:-NA}",
    "deploy_prime_url": "${DEPLOY_PRIME_URL:-NA}",
    "number": "${TRAVIS_BUILD_NUMBER:-NA}",
    "tag": "${BRANCH:-none}"
  },
  "ts": "$(date)"
}
EOT
}

function build_production()
{
  echo "---> Copying GH-PAGES Branch"
  mkdir -p ./_site/
  rsync -Ea --recursive \
  --exclude '*.md*' \
  --exclude '*.MD*' \
  --exclude '.git' \
  --exclude 'Dockerfile' \
  --exclude 'vendor' \
  --exclude 'netlify.toml' \
  --exclude 'rsync-shared' \
  --exclude '.gitignore' \
  --exclude '.travis.yml' \
  --exclude 'screenshots' \
  --exclude 'LICENSE' \
  --exclude 'dockerfiles' \
  --exclude 'tests' \
  ./ ./_site && echo "---> Copied gh-pages"
  gen_metadata;

}

function build_branch()
{
  install_dependencies;

  echo "---> Building Website with Branch"
  mkdocs build;
  gen_metadata;
}


function usage()
{
  #Prints out help menu
cat <<EOF
Usage: netlify-deploy [OPTIONS]
[-p --production]       [Production Deployment (Master Branch)]
[-b --branch]           [Branch Deployment]
[-pr --pull-request]    [Pull request deployment (Same as branch)]
EOF
}

function install_dependencies()
{
  pip install -r ./docs/requirements.txt
  mkdocs --version
  #bundle install
}


function main()
{
      #check if no args
      if [ $# -eq 0 ]; then
              echo "---> No arguments found. See usage below."
              usage;
      		    exit 1;
      fi;


      # Process command line arguments.
      while [ "$1" != "" ]; do
          case ${1} in
              -p | --production )     build_production;
                                      exit $?
                                      ;;
              -b | --branch )         build_branch;
                                      exit $?
                                      ;;
              -pr | --pull-request )  build_branch;
                                      exit $?
                                      ;;
              * )                     echo "Invalid arguments";
                                      usage;
                                      exit 1
                                      ;;
          esac
      	shift
      done
  }
#
main "$@"
