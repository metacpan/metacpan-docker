# Runnig metacpan-web in docker.

This is an experiment to run [Web interface for MetaCPAN][web] in [Docker][d].

Running metacpan-web in docker is in experimental stage.
The basic things work, but there was no heavy testing.
This way of running is not officially supported.

You can build a docker image with command:

    docker build --tag metacpan-web .

And when you have docker image you can run in with the command:

    docker run --publish 8000:5001 --detach metacpan-web

With running container you can open metacpan web at http://127.0.0.1:8000
(but you need to change 127.0.0.1 to the ip of your docker virtual machine)

If you want to run metacpan web with your custom config you can use config
file from your docker host system like this (Here is the link to the [basic config][config]):

    docker run \
        --publish 8000:5001 \
        --volume /absolute/path/to/metacpan_web.conf:/metacpan_web/metacpan_web.conf \
        --detach \
        metacpan-web

 [web]: https://github.com/CPAN-API/metacpan-web
 [d]: https://www.docker.com/
 [config]: https://github.com/CPAN-API/metacpan-web/blob/master/metacpan_web.conf
