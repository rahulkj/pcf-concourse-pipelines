#!/bin/sh

if [[ $DEBUG == true ]]; then
  set -ex
else
  set -e
fi

git clone concourse-trigger-gist updated-concourse-trigger-gist

cd updated-concourse-trigger-gist
echo $(date) > concourse-trigger

git config --global user.email "${CI_EMAIL_ADDRESS}"
git config --global user.name "${CI_USERNAME}"

git add .
git commit -m "Bumped date"
