#!/bin/bash

# clean up local docker environment
# x.x.0 always refers to private local builds
docker stop supertanker
docker rm supertanker
docker volume rm supertanker
docker image rm -f supertanker:6.0.0
docker system prune -f
docker builder prune -f