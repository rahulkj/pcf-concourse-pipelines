#!/bin/sh

if [[ $DEBUG == true ]]; then
  set -ex
else
  set -e
fi

if [[ ! -d git_repo/$FILES_PATH ]]; then
  mkdir -p git_repo/$FILES_PATH
fi

cp -r src_dir/* git_repo/$FILES_PATH/

cd git_repo

git config --global user.email "${CI_EMAIL_ADDRESS}"
git config --global user.name "${CI_USERNAME}"

git add .
git commit -m "$GIT_COMMIT_MESSAGE"
