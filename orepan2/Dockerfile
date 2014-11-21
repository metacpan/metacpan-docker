FROM ubuntu:14.04

ENV UPDATED_AT 2014-11-22

RUN apt-get update

RUN apt-get install -y \
    curl \
    gcc \
    libcurl4-openssl-dev \
    make

RUN curl -L http://cpanmin.us | perl - App::cpanminus

# This is a fix, until this ticket is solved: https://github.com/tokuhirom/OrePAN2/pull/31
RUN cpanm IO::Socket::SSL

RUN cpanm OrePAN2
