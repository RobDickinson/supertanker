# Supertanker
Supertanker is an experimental, unsupported, and definitely-not-for-production Docker container that combines Graylog, MongoDB and OpenSearch in a single package.

## Components

* Docker
* Graylog Open 6.0
* MongoDB 6.0
* OpenSearch 2.12
* Ubuntu 22.04 LTS (Jammy)

## Running Supertanker

Start container as daemon with persistent volume:

```bash
docker run -d --name supertanker -v supertanker:/data -p 9000:9000 -e GRAYLOG_HTTP_EXTERNAL_URI="http://`hostname -s`:9000/" -e GRAYLOG_PASSWORD_SECRET="somepasswordpepper" -e GRAYLOG_ROOT_PASSWORD_SHA2="8c6976e5b5410415bde908bd4dee15dfb167a9c873fc4bb8a81f6f2ab448a918" -e TZ=UTC robfromboulder/supertanker:6.0.1
```

Give this a few seconds to start before logging into http://localhost:9000 as user `admin` with password `admin`

If anything differs from how Graylog normally works on Ubuntu, please open a GitHub issue! 😀

## Stopping Supertanker

Stop container but keep all data:
```bash
docker stop supertanker
```
👆 Use `docker start supertanker` when you're ready to resume

Or permanently remove container and all stored data:
```bash
docker stop supertanker; docker rm supertanker; docker volume rm supertanker
```

## Using a Bash Shell

This container is not a walled garden, so explore and make changes as you see fit 💪

Your bash shell will run as the `runtime` user by default, which does not have root permissions. Basic commands like `nano` and `less` and `grep` will work,
but admin commands like `sudo` and `su` and `apt` will not.

The Graylog, MongoDB and OpenSearch processes running inside the container are controlled by [supervisor](http://supervisord.org/index.html), which is a
[Docker recommended solution](https://docs.docker.com/engine/containers/multi-service_container/) for running tightly-coupled services in a container.

```bash
# access container as runtime user
docker exec -it supertanker bash

# view running processes
supervisorctl status

# restart all processes
supervisorctl restart all

# view process logs
ls -hl

# quit the shell
exit
```

⚠️ For changes requiring root permissions, use the [CONTRIBUTING](CONTRIBUTING.md) guide to roll your own container.