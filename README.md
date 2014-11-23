# Running full metacpan stack with docker

## Notice

This project is in experimental stage. It works, but there are a lot of things
to be done better. Please use it and create Issues with your problems.

## Installation

 * [Install Docker](https://docs.docker.com/installation/)
 * Clone this repo
 * Build all images with the comands like:
   `cd cpan-api; docker build --tag cpan-api .`

## System architecture

The system consists of serverl microservices that live in docker containes:

 * `cpan_volume` — data volume container that shares directory `/cpan` with
   all other containers
 * `elasticsearch` — database
 * `cpan-api` — the main server — it uses `elasticsearch` and `/cpan`
    directory
 * `metacpan-web` — the web interface — it works with `cpan-api`

## cpan_volume

Eveything starts from the volume `/cpan`.

First you need to create data volume contaner:

    docker run --name cpan_volume --volume=/cpan ubuntu:14.04

Then it is possible to add some files to that volume. The simplest way is to
use `orepan2` image. But there can be other ways to populate the `/cpan`
volume. Here is a sample command that adds module from the big cpan to your
`/cpan` volume:

    docker run \
        --rm \
        --volumes-from=cpan_volume \
        orepan2 \
        orepan2-inject --author BESSARABV App::Stopwatch /cpan

One can inspect the content of the volume with one-shot container:

    docker run \
        --rm \
        --volumes-from=cpan_volume \
        ubuntu:14.04 \
        find /cpan

The output will be something like:

    /cpan
    /cpan/modules
    /cpan/modules/02packages.details.txt.gz
    /cpan/orepan2-cache.json
    /cpan/authors
    /cpan/authors/id
    /cpan/authors/id/B
    /cpan/authors/id/B/BE
    /cpan/authors/id/B/BE/BESSARABV
    /cpan/authors/id/B/BE/BESSARABV/App-Stopwatch-1.2.0.tar.gz

You also need to generate `00whois.xml` file. If you use logins from big cpan
you can get that file from cpan:

    docker run \
        --rm \
        --volumes-from=cpan_volume \
        orepan2 \
        curl -o /cpan/authors/00whois.xml cpan.cpantesters.org/authors/00whois.xml

After we have some data in `/cpan` it is possible to add webinterface to it.

## elasticsearch

First you need to run container with elasticsearch:

    docker run \
        --detach \
        --publish 9200:9200 \
        --name elasticsearch \
        elasticsearch

You can check that you have elasticsearch running with the comand:

    curl 127.0.0.1:9200

PS If you run docker on mac or windows you should change `127.0.0.1` to the ip
address of our docker virtual machinge (you can find out this ip with the
`boot2docker ip`).

Here is the output you are expecred to see:

    {
      "ok" : true,
      "status" : 200,
      "name" : "Cage, Luke",
      "version" : {
        "number" : "0.90.7",
        "build_hash" : "36897d07dadcb70886db7f149e645ed3d44eb5f2",
        "build_timestamp" : "2013-11-13T12:06:54Z",
        "build_snapshot" : false,
        "lucene_version" : "4.5.1"
      },
      "tagline" : "You Know, for Search"
    }

## cpan-api

Next you need to run cpan-api server. This can be done with the command:

    docker run \
        --detach \
        --volumes-from=cpan_volume \
        --link=elasticsearch:elasticsearch \
        --volume=$(pwd)/configs/cpan-api/metacpan.pl:/cpan-api/etc/metacpan.pl \
        --volume=$(pwd)/configs/cpan-api/metacpan_server.conf:/cpan-api/metacpan_server.conf \
        --env MINICPAN=/cpan \
        --publish 5000:5000 \
        --name cpan-api \
        cpan-api

So the server is running but you also need to run some scripts to index data.
To do it you can create ineractive container:

    docker run \
        -it \
        --rm \
        --volumes-from=cpan_volume \
        --link=elasticsearch:elasticsearch \
        --volume=$(pwd)/configs/cpan-api/metacpan.pl:/cpan-api/etc/metacpan.pl \
        --volume=$(pwd)/configs/cpan-api/metacpan_server.conf:/cpan-api/metacpan_server.conf \
        --env MINICPAN=/cpan \
        cpan-api \
        bash

And then execute all the needed scripts:

        carton exec bin/metacpan mapping --delete
        carton exec bin/metacpan release /cpan/authors/id/
        carton exec bin/metacpan latest --cpan /cpan/
        carton exec bin/metacpan author --cpan /cpan/

## metacpan-web

Then you need to run metacpan-web:

    docker run \
        --detach \
        --publish 5001:5001 \
        --link=cpan-api:cpan-api \
        --volume=$(pwd)/configs/metacpan-web/metacpan_web.conf:/root/metacpan-web/metacpan_web.conf \
        --name metacpan-web \
        metacpan-web

Open your browser at http://127.0.0.1:5001 and you will see metacpan web
interface.
