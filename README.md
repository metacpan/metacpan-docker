# MetaCPAN Docker

[![CircleCI](https://circleci.com/gh/metacpan/metacpan-docker.svg?style=svg)](https://circleci.com/gh/metacpan/metacpan-docker)

![docker compose up](https://github.com/metacpan/metacpan-docker/workflows/docker-compose%20up/badge.svg?branch=master)

<!-- vim-markdown-toc GFM -->

- [Running the MetaCPAN stack with Docker (via Docker Compose)](#running-the-metacpan-stack-with-docker-via-docker-compose)
- [Quick Start](#quick-start)
- [Working with Containers](#working-with-containers)
  - [Building Containers](#building-containers)
  - [Accessing Containers](#accessing-containers)
  - [Accessing Services](#accessing-services)
    - [`web`](#web)
    - [`api`](#api)
    - [`Elasticsearch`](#elasticsearch)
    - [`PostgreSQL`](#postgresql)
    - [`grep`](#grep)
- [System architecture](#system-architecture)
  - [The `bin/metacpan-docker` script](#the-binmetacpan-docker-script)
    - [`bin/metacpan init`](#binmetacpan-init)
    - [`bin/metacpan localapi`](#binmetacpan-localapi)
    - [`bin/metacpan-docker pull`](#binmetacpan-docker-pull)
    - [`bin/metacpan-docker reset`](#binmetacpan-docker-reset)
    - [`bin/metacpan-docker` build/up/down/start/stop/run/ps/top...](#binmetacpan-docker-buildupdownstartstoprunpstop)
  - [Services](#services)
    - [`web`](#web-1)
    - [`api`](#api-1)
    - [`grep`](#grep-1)
      - [Setting up a partial CPAN in the `api` service](#setting-up-a-partial-cpan-in-the-api-service)
      - [Bootstrapping the `elasticsearch` indices](#bootstrapping-the-elasticsearch-indices)
      - [Putting the above all together](#putting-the-above-all-together)
    - [elasticsearch and elasticsearch_test](#elasticsearch-and-elasticsearch_test)
- [Tips and tricks](#tips-and-tricks)
  - [Running your own miniCPAN inside metacpan-docker](#running-your-own-minicpan-inside-metacpan-docker)
  - [Running tests](#running-tests)
  - [Updating Carton dependencies](#updating-carton-dependencies)
  - [Updating the git repositories](#updating-the-git-repositories)
  - [Running Kibana to peek into Elasticsearch data](#running-kibana-to-peek-into-elasticsearch-data)
- [Peeking Inside the Container](#peeking-inside-the-container)
- [To Do](#to-do)
- [See also](#see-also)

<!-- vim-markdown-toc -->

## Running the MetaCPAN stack with Docker (via Docker Compose)

**Notice**: This project is in experimental stage. It works, but there are a lot
of things to be done better. Please use it and create Issues with your problems.

## Quick Start

Install [Docker][0] and [Docker Compose][1] (v2+) for your platform. [Docker for
Mac][2] or [Docker for Windows][3] will install both tools for you, if you are
on either of these environments.

[0]: https://docs.docker.com/installation
[1]: https://docs.docker.com/compose/install
[2]: https://docs.docker.com/docker-for-mac/
[3]: https://docs.docker.com/docker-for-windows/

On Debian / Ubuntu, install using:

    apt install docker-compose-v2

On Linux, Docker's default implementation only allows `root` user access to
Docker commands and to control containers. In order to allow a regular user to
access docker follow the
[post-installation instructions](https://docs.docker.com/install/linux/linux-postinstall/).
This document assumes the post-installation steps have been followed for the
current user.

You will also need Docker buildx, and to enable Docker BuildKit. They should be
set up by default when using Docker Desktop, but on Linux you may need to
install them. buildx is the `docker-buildx` package on Debian based systems.
Docker BuildKit can be enabled by following the
[Getting Started](https://docs.docker.com/build/buildkit/#getting-started)
instructions.

On Debian / Ubuntu, install using:

    apt install docker-buildx

If you are running a Mac ARM64 system, you will need to manually tell docker to
use the x86_64 version of Elasticsearch 2.4. This can be done by running the
command:

    docker pull elasticsearch:2.4 --platform=linux/x86_64

It is highly recommended that you alias `docker compose` to `fig` (its original
name) and use it wherever `docker compose` is used. You are going to have to
type this command a lot.

Then, clone this repo and set up the environment:

    git clone https://github.com/metacpan/metacpan-docker.git
    cd metacpan-docker
    bin/metacpan-docker init

The `bin/metacpan-docker init` command clones the source repositories for:

- `metacpan-web`
- `metacpan-api`
- `metacpan-grep-front-end`
- `metacpan-cpan-extracted-lite`

These repositories are automatically mounted into the appropriate docker
containers allowing the developer to use their preferred tools to work with the
source code.

The `docker compose --profile dev up` command on its own will bring up the
entire stack in the foreground (logs will be displayed).

The `docker compose --profile dev up` command will also fetch the official
container images from
[MetaCPAN Docker Hub](https://cloud.docker.com/u/metacpan/repository/list)
repositories.

This will build the Docker containers for MetaCPAN, PostgreSQL and Elasticsearch
services (which will take a while, especially on a fresh first time install of
Docker) and run the services.

Don't forget to seed the local `metacpan-api` with a partial CPAN; run the
following command in a separate terminal to get yourself up to speed:

    docker compose exec api index-cpan.sh

This will prompt you to confirm removing old indices and setting up mappings on
the Elasticsearch service (say `YES`). It will then proceed to rsync a partial
CPAN in `/CPAN` for its metadata to be imported.

After the initialization above completes, the next step is to start the web
frontend with the following command:

    docker compose up web-server

Once that is done, you should be able to see your local partial CPAN data
in e.g. [http://localhost:5001/recent](http://localhost:5001/recent) and
elsewhere.

From here, you can proceed and hack on the MetaCPAN code at `src/metacpan-api`
and/or `src/metacpan-web` directories, and saving edits will reload the
corresponding apps automatically!

When done hacking (or, more likely, when you need to rebuild/refresh your Docker
environment) you can then run

    docker compose --profile dev down

in another terminal to stop all MetaCPAN services and remove the containers.

For further details, read on!

## Working with Containers

### Building Containers

You can (re)build arbitrary containers. For instance, if you want to rebuild the
`api` container:

    docker compose build api

### Accessing Containers

Containers are accessible via the `docker compose exec` command followed by the
container and then the command to execute. For example, to start a shell prompt
in the `api` container:

    docker compose exec api /bin/bash

Executing tests via `prove` inside the API container:

    docker compose exec api_test prove -lvr \
      t/00_setup.t \
      t/01_darkpan.t \
      t/api/controller/cover.t

To access the `psql` command line client in the PostgreSQL container:

    docker compose exec pgdb psql

### Accessing Services

Each container is responsible for a different service. Some of these services
are available in the developer environment via ports on the host system.

We are using [traefik][13] to manage the traffic between services. The current
configuration is:

- api: [http://api.metacpan.localhost](http://api.metacpan.localhost)
- web: [http://web.metacpan.localhost](http://web.metacpan.localhost)
- grep: [http://grep.metacpan.localhost](http://grep.metacpan.localhost)

In order to access to the localhost subdomains, you probably have to manually
add these entries in you `/etc/hosts` file.

    # add to /etc/hosts
    127.0.0.1   api.metacpan.localhost
    127.0.0.1   gh.metacpan.localhost
    127.0.0.1   grep.metacpan.localhost
    127.0.0.1   metacpan.localhost
    127.0.0.1   web.metacpan.localhost

You can access the dashboard configuration via:
[http://metacpan.localhost:8080](http://metacpan.localhost:8080)

[0]: https://docs.traefik.io/providers/docker/

#### `web`

The local instance of the web front end is accessible via:

- [http://localhost:5001](http://localhost:5001)
- [http://web.metacpan.localhost](http://web.metacpan.localhost)

#### `api`

- [http://localhost:5000](http://localhost:5000)
- [http://api.metacpan.localhost](http://api.metacpan.localhost)

#### `Elasticsearch`

The `elasticsearch` and `elasticsearch_test` containers are not exposed
directly. They are available via the `api` and `api_test` containers.

You can query the `elasticsearch` container via:

    docker compose exec elasticsearch curl http://localhost:9200

You can query the `elasticsearch_test` container via:

    docker compose exec elasticsearch_test curl http://localhost:9200

#### `PostgreSQL`

The PostgreSQL service by default is only accessible from other containers.

#### `grep`

The grep metacpan front end is accessible via:

- [http://grep.metacpan.localhost](http://grep.metacpan.localhost)

Note: this is using a smaller, frozen version of `metacpan-cpan-extracted` via
[metacpan-cpan-extracted-lite](https://github.com/metacpan/metacpan-cpan-extracted-lite).

## System architecture

The system consists of several services that live in docker containers:

- `web` — the web interface on [http://localhost:5001](http://localhost:5001)
- `api` — the main server on [http://localhost:5000](http://localhost:5000)
- `api_test` — the api server for running tests via `prove`
- `elasticsearch` — database for `api`
- `elasticsearch_test` — database for `api_test`
- `pgdb` - PostgreSQL database container
- `logspout` - Docker log interface to [honeycomb.io](https://honeycomb.io)
- `grep` - the web interface for grep.metacpan on
  [http://localhost:3001](http://localhost:3001)

These services use one or more Docker volumes:

- `metacpan_cpan`: holds the CPAN archive, mounted in `/CPAN`
- `metacpan_elasticsearch`: holds the Elasticsearch database files
- `metacpan_elasticsearch_test`: holds the Elasticsearch test database files
- `metacpan_api_carton` and `metacpan_web_carton`: holds the dependencies
  installed by [Carton][4] for the `api` and `web` services, respectively;
  mounted on `/carton` instead of `local`, to prevent clashing with the host
  user's Carton
- `metacpan_git_shared`: points to the git repo containing all extracted CPAN
  versions. This is mounted in `/shared/metacpan_git`. This can be either
  `metacpan-cpan-extracted` or `metacpan-cpan-extracted-lite`. The volume is
  bound to the local repo at `${PWD}/src/metacpan-cpan-extracted`.

[4]: https://metacpan.org/pod/Carton

Docker Compose is used to, uh, _compose_ them all together into one system.
Using `docker compose` directly is a mouthful, however, so putting this all
together is done via the `bin/metacpan-docker` script to simplify setup and
usage (and to get you started hacking on the MetaCPAN sooner!)

### The `bin/metacpan-docker` script

`bin/metacpan-docker` is a thin wrapper around the `docker compose` command,
providing the environment variables necessary to run a basic MetaCPAN
environment. It provides these subcommands:

#### `bin/metacpan init`

The `init` subcommand basically clones the [metacpan-api][5] and
[metacpan-web][6] repositories, and sets up the git commit hooks for each of
them, in preparation for future `docker compose` or
`bin/metacpan-docker localapi` commands.

It also clones the `metacpan-grep-front-end` and `metacpan-cpan-extracted-lite`
repositories.

[5]: https://github.com/metacpan/metacpan-api
[6]: https://github.com/metacpan/metacpan-web

#### `bin/metacpan localapi`

The `localapi` subcommand adds the necessary configuration for `docker compose`
to run both the `metacpan-web` and `metacpan-api` services, along with
`elasticsearch` and Docker volumes. Under the hood, it customizes the
`COMPOSE_FILE` and `COMPOSE_PROJECT_NAME` environment variables used by
`docker compose` to use additional YAML configuration files aside from the
default `docker compose.yml`.

#### `bin/metacpan-docker pull`

This is used to update all the git repository in `src/*`. This will stay on your
current local branch.

#### `bin/metacpan-docker reset`

This is used to reset all the git repositories in `src/*` to their latest
version on `upstream/master`. This will fail if you have some uncommitted local
changes. You should then commit or cancel your changes before re-running the
command.

#### `bin/metacpan-docker` build/up/down/start/stop/run/ps/top...

As noted earlier, `bin/metacpan-docker` is a thin wrapper around
`docker compose`, so commands like `up`, `down`, and `run` will work as expected
from `docker compose`. See the [docker compose docs][7] for an overview of
available commands.

[7]:
  https://docs.docker.com/compose/reference/overview/#command-options-overview-and-help

### Services

#### `web`

The `web` service is a checkout of `metacpan-web`, built as a Docker image.
Running this service alone is enough if you want to just hack on the frontend,
since by default the service is configured to talk to
[https://fastapi.metacpan.org](https://fastapi.metacpan.org) for its backend; if
this is what you want, then you can simply invoke `docker compose up` or
`docker compose up web`.

#### `api`

The `api` service is a checkout of `metacpan-api`, built as a Docker image, just
like the `web` service.

If using this service to run a local backend, you will need to run some
additional commands in a separate terminal once
`bin/metacpan-docker localapi up` runs.

#### `grep`

The `grep` service is a checkout of `metacpan-grep-front-end`, built as a Docker
image. Note that this is using the `metacpan_git_shared` volume, which requires
the git repo for `metacpan-cpan-extracted` which can be initialized by running:

    ./bin/metacpan-docker init

##### Setting up a partial CPAN in the `api` service

Running

    bin/metacpan-docker localapi exec api partial-cpan-mirror.sh

will `rsync` modules from selected CPAN authors, plus the package and author
indices, into the `api` service's `/CPAN` directory. This is nearly equivalent
to the same script in the (now deprecated) [metacpan-developer][8] repository.
[8]: https://github.com/metacpan/metacpan-developer

##### Bootstrapping the `elasticsearch` indices

Running

    bin/metacpan-docker localapi exec api bin/run bin/metacpan mapping --delete
    bin/metacpan-docker localapi exec api bin/run bin/metacpan release /CPAN/authors/id
    bin/metacpan-docker localapi exec api bin/run bin/metacpan latest
    bin/metacpan-docker localapi exec api bin/run bin/metacpan author

in sequence will create the indices and mappings in the `elasticsearch` service,
and import the `/CPAN` data into `elasticsearch`.

##### Putting the above all together

If you're impatient or too lazy to do all the above, just running

    bin/metacpan-docker localapi exec api index-cpan.sh

instead will set it all up for you.

#### elasticsearch and elasticsearch_test

The `elasticsearch` and `elasticsearch_test` services use the official
[Elasticsearch Docker image][9], configured with settings and scripts taken from
the [metacpan-puppet][10] repository. The `api` service depends on the
`elasticsearch` service and the `api_test` service depends on the
`elasticsearch_test` services.

[9]: https://store.docker.com/images/elasticsearch
[10]: https://github.com/metacpan/metacpan-puppet

## Tips and tricks

### Running your own miniCPAN inside metacpan-docker

Suppose you have a local minicpan in `/home/ftp/pub/CPAN`. If you would like to
use this in `metacpan-docker`, then edit the `docker compose.localapi.yml` to
change the `api` service's volume mounts to use your local minicpan as `/CPAN`,
e.g.:

```yaml
services:
  api:
    volumes:
      - /home/ftp/pub/CPAN:/CPAN
      ...
```

Note that if you want CPAN author data indexed into Elasticsearch, your minicpan
should include `authors/00whois.xml`. Full indexing would take a better part of
a day or two, depending on your hardware.

### Running tests

Use `bin/metacpan-docker run` and similar:

    # Run tests for metacpan-web against fastapi.metacpan.org
    bin/metacpan-docker exec web bin/prove

    # Run tests for metacpan-web against a local api
    bin/metacpan-docker localapi exec web bin/prove

    # Run tests for metacpan-api against a local elasticsearch_test
    bin/metacpan-docker localapi exec api bin/prove

### Updating Carton dependencies

Because both the `api` and `web` services are running inside clean [Perl][11]
containers, it is possible to maintain a clean set of Carton dependencies
independent of your host machine's perl. Just update the `cpanfile` of the
project, and run

    bin/metacpan-docker exec web carton install
    # or
    bin/metacpan-docker exec api carton install

Due to the way the Compose services are configured, these commands will update
the corresponding `cpanfile.snapshot` safely, even if you do _or_ don't have a
`local` directory (internally, the containers' `local` directory is placed in
`/carton` instead, to prevent interfering with the host user's own `local`
Carton directory.)

### Updating the git repositories

You can use `bin/metacpan-docker pull` to update all `src/*` directories.

[11]: https://github.com/Perl/docker-perl

### Running Kibana to peek into Elasticsearch data

By default, the `docker compose.localapi.yml` configures the `elasticsearch`
service to listen on the Docker host at
[http://localhost:9200](http://localhost:9200), and is also accessible via the
Docker `default` network address of
[http://172.17.0.1:9200](http://172.17.0.1:9200); you can inspect it via simple
`curl` or `wget` requests, or use a [Kibana][12] container, e.g.

    docker run --rm -p 5601:5601 -e ELASTICSEARCH_URL=http://172.17.0.1:9200 -it kibana:4.6

Running the above will provide a Kibana container at
[http://localhost:5601](http://localhost:5601), which you can configure to have
it read the `cpan*` index in the `elasticsearch` service.

It is also certainly possible to run Kibana as part of the compose setup, by
configuring e.g. a `kibana` service.

[12]: https://hub.docker.com/_/kibana/

## Peeking Inside the Container

If you run `docker ps` you'll see the containers. You might see something like:

```bash
$ docker ps
CONTAINER ID        IMAGE                 COMMAND                  CREATED             STATUS                          PORTS                              NAMES
2efb9c475c83        metacpan-web:latest   "carton exec plackup…"   12 hours ago        Up 12 hours                     0.0.0.0:5001->5001/tcp             metacpan_web_1
8850110e06d8        metacpan-api:latest   "/wait-for-it.sh db:…"   12 hours ago        Up 12 hours                     0.0.0.0:5000->5000/tcp             metacpan_api_1
7686d7ea03c6        postgres:9.6-alpine   "docker-entrypoint.s…"   12 hours ago        Up 12 hours (healthy)           0.0.0.0:5432->5432/tcp             metacpan_pgdb_1
c7de256d29b2        elasticsearch:2.4     "/docker-entrypoint.…"   5 months ago        Up 26 hours                     0.0.0.0:9200->9200/tcp, 9300/tcp   metacpan_elasticsearch_1
f1e04fe53598        elasticsearch:2.4     "/docker-entrypoint.…"   5 months ago        Up 26 hours                     9300/tcp, 0.0.0.0:9900->9200/tcp   metacpan_elasticsearch_test_1
```

You can then use the container name to get shell access. For instance, to log in
to the API container:

`docker exec -it metacpan_api_1 /bin/bash`

## To Do

- Integrate all other MetaCPAN services
- Add more Tips and tricks (as we continue hacking MetaCPAN in Docker)
- Provide a "near-production" Docker Compose configuration, suitable for Docker
  Swarm, and/or
- Refactor configuration to be suitable for Kubernetes (Google Cloud)
  deployments

## See also

- [Docker Compose documentation](https://docs.docker.com/compose/overview)
- [metacpan-developer][7] and [metacpan-puppet][9] from which much information
  about the architecture is based on
