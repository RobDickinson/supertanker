# Supertanker
Supertanker is an experimental, unsupported, and definitely-not-for-production Docker container that combines Graylog, MongoDB, OpenSearch, Supervisor, and Ubuntu.

[![CodeFactor](https://www.codefactor.io/repository/github/RobDickinson/supertanker/badge)](https://www.codefactor.io/repository/github/RobDickinson/supertanker)
[![Contributing](https://img.shields.io/badge/contributions-welcome-green.svg)](https://github.com/RobDickinson/supertanker/blob/main/CONTRIBUTING.md)
[![DockerHub](https://img.shields.io/docker/v/robfromboulder/supertanker)](https://hub.docker.com/repository/docker/robfromboulder/supertanker/general)

## Running Supertanker

Start container as daemon with default settings:
```bash
docker run -d --name supertanker -v supertanker:/data -e GRAYLOG_HTTP_EXTERNAL_URI="http://localhost:9000/" -e GRAYLOG_PASSWORD_SECRET="somepasswordpepper" -e GRAYLOG_ROOT_PASSWORD_SHA2="8c6976e5b5410415bde908bd4dee15dfb167a9c873fc4bb8a81f6f2ab448a918" -e TZ=UTC -p 5044:5044/tcp -p 5140:5140/tcp -p 5140:5140/udp -p 9000:9000/tcp -p 12201:12201/tcp -p 12201:12201/udp -p 13301:13301/tcp -p 13302:13302/tcp robfromboulder/supertanker:6.0.4
```

Wait a few moments before logging into http://localhost:9000 as user `admin` with password `admin` 🎉

In Graylog, go to System/Inputs and add "GELF TCP" input with default settings.

In a terminal, submit a test message:
```bash
echo -n '{ "version": "1.1", "host": "supertanker.example.org", "short_message": "A short message", "level": 5, "_some_info": "foo" }' | nc -w0 -v localhost 12201
```
👆 Output should be `Connection to localhost port 12201 [tcp/*] succeeded!`

In Graylog, go to Search and verify the test message was captured. 🎉🎉🎉

## Running With Custom Settings

Every [configuration option](https://go2docs.graylog.org/current/setting_up_graylog/server.conf.html) for Graylog server can be set through
[environment variable](https://docs.docker.com/reference/cli/docker/container/run/#env) parameters passed to `docker run`.

This makes it easy to try out SMTP alerting and other configurations without connecting a bash shell or editing files on the container.

Each environment variable should be formatted as `-e GRAYLOG_[name]="[value]"` where `name` is in upper case. `GRAYLOG_PASSWORD_SECRET`
is a good example to copy and paste from the standard `docker run` command above.

## Using a Bash Shell

This container is not a walled garden, so explore and make changes as you like! 💪

Your bash shell will run as the `runtime` user by default, which does not have root permissions. Basic commands like `nano` and `less` and `grep` will work,
but admin commands like `sudo` and `su` and `apt` will not.

The Graylog, MongoDB and OpenSearch processes running inside the container are controlled by [supervisor](http://supervisord.org/index.html), which is a
[Docker recommended solution](https://docs.docker.com/engine/containers/multi-service_container/) for running tightly-coupled services in a container.

```bash
# access container as runtime user
docker exec -it supertanker bash

# view running processes
supervisorctl status

# start and stop processes
supervisorctl restart all
supervisorctl stop all
supervisorctl start all
supervisorctl stop graylog
supervisorctl start graylog

# view process logs
ls -hl

# quit the shell
exit
```

⚠️ For changes requiring root permissions, follow the [CONTRIBUTING](CONTRIBUTING.md) guide to connect as root or roll your own build.

## Stopping Supertanker

Stop container but keep all data:
```bash
docker stop supertanker
```
👆 Use `docker start supertanker` when you're ready to resume.

Permanently remove container and all stored data:
```bash
docker stop supertanker; docker rm supertanker; docker volume rm supertanker
```
