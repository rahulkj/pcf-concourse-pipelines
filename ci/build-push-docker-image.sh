#!/bin/bash -ex

docker build -t rjain/buildbox .
docker push rjain/buildbox
