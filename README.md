# Running the MetaCPAN stack with Docker (via Docker Compose)

**Notice**: This project is in experimental stage. It works, but there
are a lot of things to be done better. Please use it and create Issues
with your problems.

## Quick Start

Install [Docker][0] and [Docker Compose][1] for your platform.  On Mac
and Cheese (er, Windows) environments, [Docker Toolbox][2] will install
both tools for you.  It is however, recommended to run directly on
Linux, for native container support, and less issues overall.

[0]: https://docs.docker.com/installation
[1]: https://docs.docker.com/compose/install
[2]: https://www.docker.com/products/docker-toolbox

Then, clone this repo and setup the environment:

    git clone https://github.com/metacpan/metacpan-docker.git
    cd metacpan-docker
    bin/metacpan-docker init

After this, you can run both the `metacpan-web` frontend on
http://localhost:5001 and the `metacpan-api` backend on
http://localhost:5000, with ElasticSearch on http://localhost:9200, via

    bin/metacpan-docker localapi up

This will build the Docker images for the MetaCPAN and ElasticSearch
services (which will take a while, especially on a fresh first time
install of Docker,) and run the services.  You'll know when they're
ready when the services start listening on the ports listed above.

Don't forget to seed the local `metacpan-api` with a partial CPAN; run
the following command in a separate terminal to get you up to speed:

    bin/metacpan-docker localapi run --rm api index-cpan.sh

Once the above is done, you should be able to see your local partial
CPAN data in e.g. http://localhost:5001/recent and elsewhere.

Alternatively, if you just want to hack on the web frontend, you can run
this instead of all the above:

    docker-compose up

From here, you can proceed and hack on the MetaCPAN code at
`src/metacpan-api` and/or `src/metacpan-web` directories, and saving
edits will reload the corresponding apps automatically!

When done hacking (or, more likely, when you need to rebuild/refresh
your Docker environment) you can then run

    bin/metacpan-docker localapi down
    # or, if running the metacpan-web service only
    docker-compose down 

in another terminal to stop all MetaCPAN services and remove the
containers.

For further details, read on!

## System architecture

The system consists of several services that live in docker containers:

 * `web` — the web interface on http://localhost:5001
 * `api` — the main server on http://localhost:5000
 * `elasticsearch` — database on http://localhost:9200
 * `elasticsearch_test` — test database on http://localhost:9300
 
These services use one or more Docker volumes:

 * `metacpan_cpan`: holds the CPAN archive, mounted in `/CPAN`
 * `metacpan_elasticsearch`: holds the ElasticSearch database files
 * `metacpan_elasticsearch_test`: holds the ElasticSearch test database
   files
 * `metacpan_api_carton` and `metacpan_web_carton`: holds the
   dependencies installed by [Carton][3] for the `api` and `web`
   services, respectively; mounted on `/carton` instead of `local`, to
   prevent clashing with the host user's Carton
   
[3]: https://metacpan.org/pod/Carton
 
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

The `init` subcommand basically clones the [metacpan-api][4]
and [metacpan-web][5] repositories, and sets up the git commit hooks for
each of them, in preparation for future `docker-compose` or
`bin/metacpan-docker localapi` commands.

[4]: https://github.com/metacpan/metacpan-api
[5]: https://github.com/metacpan/metacpan-web

#### `bin/metacpan localapi`

The `localapi` subcommand adds the necessary configuration for
`docker-compose` to run both the `metacpan-web` and `metacpan-api`
services, along with `elasticsearch` and Docker volumes.  Under the
hood, it customizes the `COMPOSE_FILE` and `COMPOSE_PROJECT_NAME`
environment variables used by `docker-compose` to use additional YAML
configuration files aside from the default `docker-compose.yml`.

#### `bin/metacpan-docker` build/up/down/start/stop/run/ps/top...

As noted earlier, `bin/metacpan-docker` is a thin wrapper to
`docker-compose`, so commands like `up`, `down`, and `run` will
work as expected from `docker-compose`.  See the [docker-compose docs][6]

[6]: https://docs.docker.com/compose/reference/overview/#command-options-overview-and-help

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

    bin/metacpan-docker localapi run --rm api partial-cpan-mirror.sh

will `rsync` modules selected CPAN authors, plus the package and author
indices, into the `api` service's `/CPAN` directory.  This is nearly
equivalent to the same script in the [metacpan-developer][7] repository.
    
[7]: https://github.com/metacpan/metacpan-developer

##### Bootstrapping the `elasticsearch` indices

Running

    bin/metacpan-docker localapi run --rm api bin/run bin/metacpan mapping --delete
    bin/metacpan-docker localapi run --rm api bin/run bin/metacpan release /CPAN/authors/id
    bin/metacpan-docker localapi run --rm api bin/run bin/metacpan latest
    bin/metacpan-docker localapi run --rm api bin/run bin/metacpan author

in sequence will create the indices and mappings in the `elasticsearch`
service, and import the `/CPAN` data into `elasticsearch`.

##### Putting the above all together

If you're impatient or lazy to do all the above, just running

    bin/metacpan-docker localapi run --rm api index-cpan.sh
    
instead will set it all up for you.

By the way, in case you're curious: these `localapi run` commands start
a temporary container separate from the service containers; the `--rm`
flag tells the underlying `docker-compose` to remove this container
afterwards.

#### elasticsearch and elasticsearch_test

The `elasticsearch` and `elasticsearch_test` services uses the
official [ElasticSearch Docker image][8], configured with settings and
scripts taken from the [metacpan-puppet][9] repository.  It is depended
on by the `api` service.

[8]: https://store.docker.com/images/elasticsearch
[9]: https://github.com/metacpan/metacpan-puppet

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
    bin/metacpan-docker run --rm web bin/prove
    
    # Run tests for metacpan-web against local api
    bin/metacpan-docker localapi run --rm web bin/prove

    # Run tests for metacpan-api against local elasticsearch_test
    bin/metacpan-docker localapi run --rm api bin/prove

### Updating Carton dependencies

Because both the `api` and `web` services are running inside
clean [Perl][10] containers, it is possible to maintain a clean set of
Carton dependencies independent of your host machine's perl.  Just
update the `cpanfile` of the project, and run

    bin/metacpan run --rm web carton install
    # or
    bin/metacpan run --rm api carton install 
    
Due to the way the Compose services are configured, these commands will
update the corresponding `cpanfile.snapshot` safely, even if you do _or_
don't have a `local` directory (internally, the containers' `local`
directory is placed in `/carton` instead, to prevent interfering with
the host user's own `local` Carton directory.)

[10]: https://github.com/Perl/docker-perl
    
### Running Kibana to peek into ElasticSearch data

By default, the `docker-compose.localapi.yml` configures the
`elasticsearch` service to listen on the Docker host at
http://localhost:9200; you can inspect it via simple `curl` or `wget`
requests, or use a [Kibana][11] container, e.g.

    docker run --rm -p 5601:5601 -e ELASTICSEARCH_URL=http://localhost:9200 -it kibana:4.6 

Running the above will provide a Kibana container at
http://localhost:5601, which you can configure to have it read the
`cpan*` index in the `elasticsearch` service.

It is also certainly possible to run Kibana as part of the compose
setup, by configuring e.g. a `kibana` service.

[11]: https://hub.docker.com/_/kibana/

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
