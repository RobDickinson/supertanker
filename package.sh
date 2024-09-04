#!/bin/bash
docker stop supertanker
docker rm supertanker
docker image rm -f supertanker:6.0.0
docker system prune -f
docker build --build-arg VERSION=6.0.0 -f container.dockerfile -t supertanker:6.0.0 --no-cache .