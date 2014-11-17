
You can build a docker image with command:

    docker build --tag elasticsearch .

And then run it:

    docker run --publish 9200:9200 elasticsearch

Then you can test that elasticsearch is working with the command (it takes
about 10 seconds after `docker run` command):

    curl 127.0.0.1:49153
