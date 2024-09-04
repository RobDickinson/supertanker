# Contributing to supertanker

## Building Local Containers

```bash
# stop local container and reset build state
bash clean.sh

# build local container
bash package.sh

# run local container without durable storage
docker run -d --name supertanker --rm --tmpfs /data -p 9000:9000 -e GRAYLOG_HTTP_EXTERNAL_URI="http://localhost:9000/" -e GRAYLOG_PASSWORD_SECRET="somepasswordpepper" -e GRAYLOG_ROOT_PASSWORD_SHA2="8c6976e5b5410415bde908bd4dee15dfb167a9c873fc4bb8a81f6f2ab448a918" supertanker:6.0.0

# access local container as root user
docker exec -it --user root supertanker bash
```

## Container Versioning

* Your local builds will always be versioned `supertanker:6.0.0`
* Public release builds will never use version `6.0.0` by convention
* This makes it easy to distinguish local and public builds when testing

## Applying Security Updates

* Update `container.dockerfile` when new Ubuntu base versions become available
* Let `apt update` and `apt upgrade` do the heavy lifting
* Scan the container image prior to release: `trivy image supertanker:6.0.0`

## Release Process

The local build is for the native chipset only, but the release build is for both `amd64` and `arm64` architectures.

Configure `buildx` if not already done:

```bash
docker buildx ls
docker buildx create --name mybuilder
docker buildx use mybuilder
```

Build and push containers:

```bash
bash packagex.sh 6.0.(BUILD_NUMBER)
```

Add release tag:

```
git tag v6.0.(BUILD_NUMBER)
git push origin v6.0.x --tags
```
