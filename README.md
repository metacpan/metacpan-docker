# MetaCPAN Docker


<!-- vim-markdown-toc GFM -->

* [Running the MetaCPAN stack with Docker (via Docker Compose)](#running-the-metacpan-stack-with-docker-via-docker-compose)
* [Quick Start](#quick-start)
* [System architecture](#system-architecture)
  * [The `bin/metacpan-docker` script](#the-binmetacpan-docker-script)
    * [`bin/metacpan init`](#binmetacpan-init)
    * [`bin/metacpan localapi`](#binmetacpan-localapi)
    * [`bin/metacpan-docker` build/up/down/start/stop/run/ps/top...](#binmetacpan-docker-buildupdownstartstoprunpstop)
  * [Services](#services)
    * [`web`](#web)
    * [`api`](#api)
      * [Setting up a partial CPAN in the `api` service](#setting-up-a-partial-cpan-in-the-api-service)
      * [Bootstrapping the `elasticsearch` indices](#bootstrapping-the-elasticsearch-indices)
      * [Putting the above all together](#putting-the-above-all-together)
    * [elasticsearch and elasticsearch_test](#elasticsearch-and-elasticsearch_test)
* [Tips and tricks](#tips-and-tricks)
  * [Running your own miniCPAN inside metacpan-docker](#running-your-own-minicpan-inside-metacpan-docker)
  * [Running tests](#running-tests)
  * [Updating Carton dependencies](#updating-carton-dependencies)
  * [Running Kibana to peek into ElasticSearch data](#running-kibana-to-peek-into-elasticsearch-data)
* [Peeking Inside the Container](#peeking-inside-the-container)
* [To Do](#to-do)
* [See also](#see-also)

<!-- vim-markdown-toc -->

## Running the MetaCPAN stack with Docker (via Docker Compose)

**Notice**: This project is in experimental stage. It works, but there
are a lot of things to be done better. Please use it and create Issues
with your problems.

## Quick Start

Install [Docker][0] and [Docker Compose][1] for your
platform.  [Docker for Mac][2] or [Docker for Windows][3] will install
both tools for you, if you are on either of these environments.  It is
however, recommended to run directly on Linux, for native container
support, and less issues overall.

[0]: https://docs.docker.com/installation
[1]: https://docs.docker.com/compose/install
[2]: https://docs.docker.com/docker-for-mac/
[3]: https://docs.docker.com/docker-for-windows/

On Linux, Docker's default implementation allows only `root` user to access
docker commands and control containers. In order to allow a regular user to
access docker follow the
[post-installation instructions](https://docs.docker.com/install/linux/linux-postinstall/).
This document assumes the post-installation steps have been followed for the
current user.

It is recommended that you alias `docker-compose` to `fig` (the rest of the
document assumes you have done so). You are going to have to type this command
a lot.

Then, clone this repo and setup the environment:

    git clone https://github.com/metacpan/metacpan-docker.git
    cd metacpan-docker
    bin/metacpan-docker init

The `bin/metacpan-docker init` command clones the source repositories for:
- `metacpan-web`
- `metacpan-api`

These repositories are automatically mounted in to the appropriate docker
containers allowing the developer to use their preferred tools to work with the
source code.

The `fig up` command on its own will bring up the entire stack.

After issuing `fig up`, you can run both the `metacpan-web` frontend on
http://localhost:5001 and the `metacpan-api` backend on
http://localhost:5000, with ElasticSearch on http://localhost:9200, via

The `fig up` command will fetch the official container images from
[MetaCPAN Docker Hub](https://cloud.docker.com/u/metacpan/repository/list)
repositories.

This will build the Docker images for the MetaCPAN and ElasticSearch
services (which will take a while, especially on a fresh first time
install of Docker,) and run the services.  You'll know when they're
ready when the services start listening on the ports listed above.

Don't forget to seed the local `metacpan-api` with a partial CPAN; run
the following command in a separate terminal to get you up to speed:

    fig exec api index-cpan.sh

This will prompt you to confirm removing old indices and setting up
mappings on the ElasticSearch service (say `YES`) then proceed to rsync
a partial CPAN in `/CPAN` for its metadata to be imported.

Once the above is done, you should be able to see your local partial CPAN data
in e.g. [http://localhost:5001/recent](http://localhost:5001/recent) and
elsewhere.

Alternatively, if you just want to hack on the web frontend, you can run
this instead of all the above:

    fig up web

From here, you can proceed and hack on the MetaCPAN code at
`src/metacpan-api` and/or `src/metacpan-web` directories, and saving
edits will reload the corresponding apps automatically!

When done hacking (or, more likely, when you need to rebuild/refresh
your Docker environment) you can then run

    fig down

in another terminal to stop all MetaCPAN services and remove the
containers.

For further details, read on!

## System architecture

The system consists of several services that live in docker containers:

 * `web` — the web interface on http://localhost:5001
 * `api` — the main server on http://localhost:5000
 * `elasticsearch` — database on http://localhost:9200
 * `elasticsearch_test` — test database on http://localhost:9300
 * `pgdb` - PostgreSQL database container
 * `logspout` - Docker log interface to honeycomb.io
 * `github-meets-cpan` - Containerized version of `gh.metacpan.org`

These services use one or more Docker volumes:

 * `metacpan_cpan`: holds the CPAN archive, mounted in `/CPAN`
 * `metacpan_elasticsearch`: holds the ElasticSearch database files
 * `metacpan_elasticsearch_test`: holds the ElasticSearch test database
   files
 * `metacpan_api_carton` and `metacpan_web_carton`: holds the
   dependencies installed by [Carton][4] for the `api` and `web`
   services, respectively; mounted on `/carton` instead of `local`, to
   prevent clashing with the host user's Carton
   
[4]: https://metacpan.org/pod/Carton
 
Docker Compose is used to, uh, _compose_ them all together into one
system.  Using `docker-compose` directly is a mouthful, however, so
putting this all together is done via the `bin/metacpan-docker` script
to simplify setup and usage (and to get you started hacking on the
MetaCPAN sooner!)

### The `bin/metacpan-docker` script

`bin/metacpan-docker` is a thin wrapper for the `docker-compose`
command, providing the environment variables necessary to run a basic
MetaCPAN environment. It provides these subcommands:

#### `bin/metacpan init`

The `init` subcommand basically clones the [metacpan-api][5]
and [metacpan-web][6] repositories, and sets up the git commit hooks for
each of them, in preparation for future `docker-compose` or
`bin/metacpan-docker localapi` commands.

[5]: https://github.com/metacpan/metacpan-api
[6]: https://github.com/metacpan/metacpan-web

#### `bin/metacpan localapi`

The `localapi` subcommand adds the necessary configuration for
`docker-compose` to run both the `metacpan-web` and `metacpan-api`
services, along with `elasticsearch` and Docker volumes.  Under the
hood, it customizes the `COMPOSE_FILE` and `COMPOSE_PROJECT_NAME`
environment variables used by `docker-compose` to use additional YAML
configuration files aside from the default `docker-compose.yml`.

#### `bin/metacpan-docker` build/up/down/start/stop/run/ps/top...

As noted earlier, `bin/metacpan-docker` is a thin wrapper to
`docker-compose`, so commands like `up`, `down`, and `run` will work as
expected from `docker-compose`.  See the [docker-compose docs][7] for an
overview of available commands.

[7]: https://docs.docker.com/compose/reference/overview/#command-options-overview-and-help

### Services

#### `web`

The `web` service is a checkout of `metacpan-web`, built as a Docker
image.  Running this service alone is enough if you want to just hack on
the frontend, since by default the service is configured to talk to
https://fastapi.metacpan.org for its backend; if this is what you want,
then you can simply invoke `docker-compose up`.

#### `api`

The `api` service is a checkout of `metacpan-api`, built as a Docker
image, just like the `web` service.

If using this service to run a local backend, you will need to run some
additional commands in a separate terminal once `bin/metacpan-docker
localapi up` runs:

##### Setting up a partial CPAN in the `api` service

Running

    bin/metacpan-docker localapi exec api partial-cpan-mirror.sh

will `rsync` modules selected CPAN authors, plus the package and author
indices, into the `api` service's `/CPAN` directory.  This is nearly
equivalent to the same script in the [metacpan-developer][8] repository.
    
[8]: https://github.com/metacpan/metacpan-developer

##### Bootstrapping the `elasticsearch` indices

Running

    bin/metacpan-docker localapi exec api bin/run bin/metacpan mapping --delete
    bin/metacpan-docker localapi exec api bin/run bin/metacpan release /CPAN/authors/id
    bin/metacpan-docker localapi exec api bin/run bin/metacpan latest
    bin/metacpan-docker localapi exec api bin/run bin/metacpan author

in sequence will create the indices and mappings in the `elasticsearch`
service, and import the `/CPAN` data into `elasticsearch`.

##### Putting the above all together

If you're impatient or lazy to do all the above, just running

    bin/metacpan-docker localapi exec api index-cpan.sh
    
instead will set it all up for you.

#### elasticsearch and elasticsearch_test

The `elasticsearch` and `elasticsearch_test` services uses the
official [ElasticSearch Docker image][9], configured with settings and
scripts taken from the [metacpan-puppet][10] repository.  It is depended
on by the `api` service.

[9]: https://store.docker.com/images/elasticsearch
[10]: https://github.com/metacpan/metacpan-puppet

## Tips and tricks

### Running your own miniCPAN inside metacpan-docker

Suppose you have a local minicpan in `/home/ftp/pub/CPAN`.  If you would
like to use this in metacpan-docker, then edit the
`docker-compose.localapi.yml` to change the `api` service's volume
mounts to use your local minicpan as `/CPAN`, e.g.:

```yaml
services:
  api:
    volumes:
      - /home/ftp/pub/CPAN:/CPAN
      ...
```

Note that if you want CPAN author data indexed into ElasticSearch, your
minicpan should include `authors/00whois.xml`.  Full indexing would take
a better part of a day or two, depending on your hardware.

### Running tests

Use `bin/metacpan-docker run` and similar:

    # Run tests for metacpan-web against fastapi.metacpan.org
    bin/metacpan-docker exec web bin/prove
    
    # Run tests for metacpan-web against local api
    bin/metacpan-docker localapi exec web bin/prove

    # Run tests for metacpan-api against local elasticsearch_test
    bin/metacpan-docker localapi exec api bin/prove

### Updating Carton dependencies

Because both the `api` and `web` services are running inside
clean [Perl][11] containers, it is possible to maintain a clean set of
Carton dependencies independent of your host machine's perl.  Just
update the `cpanfile` of the project, and run

    bin/metacpan-docker exec web carton install
    # or
    bin/metacpan-docker exec api carton install 
    
Due to the way the Compose services are configured, these commands will
update the corresponding `cpanfile.snapshot` safely, even if you do _or_
don't have a `local` directory (internally, the containers' `local`
directory is placed in `/carton` instead, to prevent interfering with
the host user's own `local` Carton directory.)

[11]: https://github.com/Perl/docker-perl
    
### Running Kibana to peek into ElasticSearch data

By default, the `docker-compose.localapi.yml` configures the
`elasticsearch` service to listen on the Docker host at
http://localhost:9200, and is also accessible via the Docker `default`
network address of http://172.17.0.1:9200; you can inspect it via simple
`curl` or `wget` requests, or use a [Kibana][12] container, e.g.

    docker run --rm -p 5601:5601 -e ELASTICSEARCH_URL=http://172.17.0.1:9200 -it kibana:4.6

Running the above will provide a Kibana container at
http://localhost:5601, which you can configure to have it read the
`cpan*` index in the `elasticsearch` service.

It is also certainly possible to run Kibana as part of the compose
setup, by configuring e.g. a `kibana` service.

[12]: https://hub.docker.com/_/kibana/

## Peeking Inside the Container

If you run `docker ps` you'll see the containers.  You might see something like:

```
$ docker ps
CONTAINER ID        IMAGE                 COMMAND                  CREATED             STATUS                          PORTS                              NAMES
2efb9c475c83        metacpan-web:latest   "carton exec plackup…"   12 hours ago        Up 12 hours                     0.0.0.0:5001->5001/tcp             metacpan_web_1
8850110e06d8        metacpan-api:latest   "/wait-for-it.sh db:…"   12 hours ago        Up 12 hours                     0.0.0.0:5000->5000/tcp             metacpan_api_1
7686d7ea03c6        postgres:9.6-alpine   "docker-entrypoint.s…"   12 hours ago        Up 12 hours (healthy)           0.0.0.0:5432->5432/tcp             metacpan_pgdb_1
c7de256d29b2        elasticsearch:2.4     "/docker-entrypoint.…"   5 months ago        Up 26 hours                     0.0.0.0:9200->9200/tcp, 9300/tcp   metacpan_elasticsearch_1
f1e04fe53598        elasticsearch:2.4     "/docker-entrypoint.…"   5 months ago        Up 26 hours                     9300/tcp, 0.0.0.0:9900->9200/tcp   metacpan_elasticsearch_test_1
```

You can then use the container name to get shell access.  For instance, to log in to the API container:

`docker exec -it metacpan_api_1 /bin/bash`

## To Do

 * Integrate other MetaCPAN services (e.g. github-meets-cpan)
 * Add more Tips and tricks (as we continue hacking MetaCPAN in Docker)
 * Provide a "near-production" Docker Compose configuration, suitable
   for Docker Swarm, and/or
 * Refactor configuration to be suitable for Kubernetes (Google Cloud)
   deployments

## See also

 * [Docker Compose documentation](https://docs.docker.com/compose/overview)
 * [metacpan-developer][7] and [metacpan-puppet][9] from which much
   information about the architecture is based on
