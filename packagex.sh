#!/bin/bash
docker stop supertanker
docker rm supertanker
docker volume rm supertanker
docker image rm -f supertanker:6.1.0
docker system prune -f
docker buildx build --platform linux/amd64,linux/arm64 --build-arg VERSION=$1 -f container.dockerfile -t robfromboulder/supertanker:$1 --no-cache --push .