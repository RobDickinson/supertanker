# Contributing to Supertanker

## Building Local Containers

Stop local container and reset build state:
```bash
bash clean.sh
```

Build local container:
```bash
bash package.sh
```

Test local container:
```bash
docker run -d --name supertanker --rm -e GRAYLOG_HTTP_EXTERNAL_URI="http://localhost:9000/" -e GRAYLOG_PASSWORD_SECRET="somepasswordpepper" -e GRAYLOG_ROOT_PASSWORD_SHA2="8c6976e5b5410415bde908bd4dee15dfb167a9c873fc4bb8a81f6f2ab448a918" -p 5044:5044/tcp -p 5140:5140/tcp -p 5140:5140/udp -p 9000:9000/tcp -p 12201:12201/tcp -p 12201:12201/udp -p 13301:13301/tcp -p 13302:13302/tcp supertanker:6.1.0
```

Access local container as root user:
```bash
docker exec -it --user root supertanker bash
```

Stop local container:
```bash
docker stop supertanker
```

## Applying Security Updates

* Update `container.dockerfile` when new Ubuntu base versions become available
* Let `apt update` and `apt upgrade` do the heavy lifting
* Scan the container image: `trivy image supertanker:6.1.0`

## GitHub Workflow

This workflow allows you to easily create your own copy of supertanker, try out some changes, and then share your changes back to be merged, with feedback from other contributors.

1. Create a fork of RobDickinson/supertanker
2. Create a feature branch
3. Build and test local changes
4. Commit changes to your feature branch
5. Open a pull request
6. Participate in code review
7. Celebrate your accomplishment

## Container Versioning

* Your local builds will always be versioned `6.1.0` (and this is assumed by build scripts)
* Public release numbers use the installed Graylog version and a patch version like this: `6.1.beta1` (for 1st beta) or `6.1.0c` (for 3rd build of 6.1.0) 
* This makes it easy to identify what version of Graylog is bundled, and reduces chance of confusing local and public builds

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
bash packagex.sh 6.1.(BUILD_NUMBER)(BUILD_LETTER)
```

Update version number shown in README and commit this change.

Add release tag:
```bash
git tag 6.1.(BUILD_NUMBER)(BUILD_LETTER)
git push origin v6.1.x --tags
```
