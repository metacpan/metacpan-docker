# Running full metacpan stack with docker

## Notice

This project is in experimental stage. It works, but there are a lot of things
to be done better. Please use it and create Issues with your problems.

## Installation

 * You need docker and docker-compose. The simplest way to get them is to
   [install Docker Toolbox](https://www.docker.com/docker-toolbox)
 * Clone this repo
 * Build and start everything with `./build && ./start`

Open your browser at http://127.0.0.1:5001 and you will see metacpan web
interface.

## System architecture

The system consists of several microservices that live in docker containers:

 * `storage` — data volume container that shares directory `/cpan` with
   all other containers
 * `elasticsearch` — database
 * `cpan-api` — the main server — it uses `elasticsearch` and `/cpan`
    directory
 * `metacpan-web` — the web interface — it works with `cpan-api`
