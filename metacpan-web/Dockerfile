
# Warning!
#
# Running metacpan-web in docker is in experimental stage.
# The basic things work, but there was no heavy testing.
# This way of running is not officially supported.

FROM ubuntu:14.04.3

RUN apt-get update && apt-get install -y \
    curl \
    gcc \
    git \
    libcurl4-openssl-dev \
    libexpat1-dev \
    libxml2-dev \
    make

RUN curl --silent https://raw.githubusercontent.com/miyagawa/cpanminus/1.7039/cpanm | perl - App::cpanminus
RUN cpanm Carton@v1.0.22

WORKDIR /app

RUN git clone https://github.com/CPAN-API/metacpan-web.git /app/ \
    && git checkout -b tmp d20c1b6dc4235dac31f66608e3a03ea9de7b8565

RUN carton install --deployment

EXPOSE 5001

CMD ["carton", "exec", "plackup", "-p", "5001", "-r"]
