FROM ubuntu:14.04

ENV UPDATED_AT 2014-11-10

RUN apt-get update

RUN apt-get install -y \
    curl \
    gcc \
    make

RUN curl -L http://cpanmin.us | perl - App::cpanminus

RUN cpanm OrePAN2
