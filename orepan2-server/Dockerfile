FROM ubuntu:14.04

ENV UPDATED_AT 2014-11-23

RUN apt-get update

RUN apt-get install -y \
    curl \
    gcc \
    git \
    libcurl4-openssl-dev \
    make

RUN curl -L http://cpanmin.us | perl - App::cpanminus

RUN git config --global user.email "robot@example.com"
RUN git config --global user.email "The Robot"

# Temporary. to create cache
RUN cpanm OrePAN2

# This does not work
RUN cpanm OrePAN2::Server
