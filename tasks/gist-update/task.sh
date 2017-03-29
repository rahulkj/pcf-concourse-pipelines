#!/bin/sh -ex

git clone concourse-trigger-gist

cd concourse-trigger-gist
echo $(date) >

git config --global user.email "${CI_EMAIL_ADDRESS}"
git config --global user.name "${CI_USERNAME}"

git add .
git commit -m "Bumped date"
