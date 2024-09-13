# Supertanker
Supertanker is an experimental, unsupported, and definitely-not-for-production Docker container that combines Graylog, MongoDB, OpenSearch, Supervisor, and Ubuntu.

[![CodeFactor](https://www.codefactor.io/repository/github/RobDickinson/supertanker/badge)](https://www.codefactor.io/repository/github/RobDickinson/supertanker)
[![Contributing](https://img.shields.io/badge/contributions-welcome-green.svg)](https://github.com/RobDickinson/supertanker/blob/v6.1.x/CONTRIBUTING.md)

## System Requirements

* Docker Desktop for Windows (WSL 2)
* Docker Desktop for Mac (Intel and Apple Silicon)
* Docker for Linux 
    * requires `vm.max_map_count=262144`
    * to check value: `sudo sysctl vm.max_map_count`
    * if not set, add `vm.max_map_count=262144` to `/etc/sysctl.conf`


## Running With Docker

Recommended when you just wanna run Graylog with the fewest possible steps.

### Starting Supertanker

Start container as daemon with default (insecure) settings:
```bash
docker run -d --name supertanker -v supertanker:/data -e GRAYLOG_DATANODE_INSECURE_STARTUP="true" -e GRAYLOG_DATANODE_PASSWORD_SECRET="somepasswordpeppersomepasswordpeppersomepasswordpeppersomepasswordpepper" -e GRAYLOG_HTTP_EXTERNAL_URI="http://localhost:9000/" -e GRAYLOG_PASSWORD_SECRET="somepasswordpeppersomepasswordpeppersomepasswordpeppersomepasswordpepper" -e GRAYLOG_ROOT_PASSWORD_SHA2="8c6976e5b5410415bde908bd4dee15dfb167a9c873fc4bb8a81f6f2ab448a918" -e TZ=UTC -p 5044:5044/tcp -p 5140:5140/tcp -p 5140:5140/udp -p 9000:9000/tcp -p 12201:12201/tcp -p 12201:12201/udp -p 13301:13301/tcp -p 13302:13302/tcp robfromboulder/supertanker:6.1.beta1-datanode
```

👆 Every [configuration option](https://go2docs.graylog.org/current/setting_up_graylog/server.conf.html) for Graylog server can be set through
[environment variable](https://docs.docker.com/reference/cli/docker/container/run/#env) parameters passed to `docker run`. This makes it
easy to try out SMTP alerting and other configurations without connecting a bash shell or editing files on the container. Each environment variable
should be formatted as `-e GRAYLOG_[name]="[value]"` where `name` is in upper case.

### Logging Into Graylog

Wait a few moments before logging into http://localhost:9000 as user `admin` with password `admin` 🎉

### Stopping Supertanker

Stop container but keep all data:
```bash
docker stop supertanker
```
👆 Use `docker start supertanker` when you're ready to resume.

Permanently remove container and all stored data:
```bash
docker stop supertanker; docker rm supertanker; docker volume rm supertanker
```


## Running With Docker Compose

Recommended when using Supertanker as a component in a larger Compose application.

### Defining the Application

Create `my_supertanker_app.yml` like this:
```yaml
services:
  supertanker:
    container_name: supertanker
    image: "robfromboulder/supertanker:6.1.beta1-datanode"
    environment:
      GRAYLOG_DATANODE_INSECURE_STARTUP: "true"
      GRAYLOG_DATANODE_PASSWORD_SECRET: "somepasswordpeppersomepasswordpeppersomepasswordpeppersomepasswordpepper"
      GRAYLOG_HTTP_EXTERNAL_URI: "http://localhost:9000/"
      GRAYLOG_PASSWORD_SECRET: "somepasswordpeppersomepasswordpeppersomepasswordpeppersomepasswordpepper"
      GRAYLOG_ROOT_PASSWORD_SHA2: "8c6976e5b5410415bde908bd4dee15dfb167a9c873fc4bb8a81f6f2ab448a918"
      TZ: UTC
    ports:
      - "9000:9000/tcp"
      - "5044:5044/tcp"
      - "5140:5140/tcp"
      - "5140:5140/udp"
      - "12201:12201/tcp"
      - "12201:12201/udp"
      - "13301:13301/tcp"
      - "13302:13302/tcp"
    volumes:
      - supertanker:/data

volumes:
  supertanker:
    driver: local
```
👆 Every [configuration option](https://go2docs.graylog.org/current/setting_up_graylog/server.conf.html) for Graylog server can be set through environment
variables. This makes it easy to try out SMTP alerting and other configurations without connecting a bash shell or editing files on the container.
Each environment variable should be formatted on its own line as `GRAYLOG_[name]: "[value]"` where `name` is in upper case.

### Starting the Application

```bash
docker compose -f my_supertanker_app.yml up --detach
```

Wait a few moments before logging into http://localhost:9000 as user `admin` with password `admin` 🎉

### Stopping the Application

Stop containers but keep volumes:
```bash
docker compose -f my_supertanker_app.yml down
```

Permanently remove containers and volumes:
```bash
docker compose -f my_supertanker_app.yml down --remove-orphans --volumes
```


## Sending Test Messages

In Graylog, go to System/Inputs and add "GELF TCP" input with default settings.

In a terminal, submit a test message:
```bash
echo -n '{ "version": "1.1", "host": "supertanker.example.org", "short_message": "A short message", "level": 5, "_some_info": "foo" }' | nc -w0 -v localhost 12201
```
👆 Output should be `Connection to localhost port 12201 [tcp/*] succeeded!`

In Graylog, go to Search and verify the test message was captured. 🎉🎉🎉


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

⚠️ For changes requiring root permissions, see [CONTRIBUTING](CONTRIBUTING.md) to connect as root or roll your own build.
