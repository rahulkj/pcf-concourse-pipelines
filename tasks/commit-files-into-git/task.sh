#!/bin/bash

if [[ $DEBUG == true ]]; then
  set -eux
else
  set -eu
fi

if [ ! -d "git_repo/$FILES_PATH" ]; then
  mkdir -p git_repo/$FILES_PATH
fi

cp -r src_dir/* git_repo/$FILES_PATH/

pushd git_repo
  git config --global user.email "${CI_EMAIL_ADDRESS}"
  git config --global user.name "${CI_USERNAME}"

  git add .
  git commit -m "$GIT_COMMIT_MESSAGE"
popd
