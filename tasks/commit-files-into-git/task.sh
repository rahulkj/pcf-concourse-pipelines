#!/bin/bash

if [[ $DEBUG == true ]]; then
  set -eux
else
  set -eu
fi

git clone git-repo git-repo-updated

cp -r src-dir/* git-repo-updated/

pushd git-repo-updated
  if [[ -n "$(git status -s)" ]]; then
    git config --global user.email "${CI_EMAIL_ADDRESS}"
    git config --global user.name "${CI_USERNAME}"

    git add .
    git commit -m "$GIT_COMMIT_MESSAGE"
  fi
popd
