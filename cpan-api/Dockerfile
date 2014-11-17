FROM ubuntu:14.04

ENV UPDATED_AT 2014-11-17

RUN apt-get update

RUN apt-get install -y \
    curl \
    gcc \
    git \
    libcurl4-openssl-dev \
    libexpat1-dev \
    libxml2-dev \
    make

RUN curl -L http://cpanmin.us | perl - App::cpanminus

RUN cpanm Carton

RUN git clone https://github.com/CPAN-API/cpan-api.git /cpan-api/

WORKDIR /cpan-api/

RUN carton install
