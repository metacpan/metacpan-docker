FROM ubuntu:14.04

ENV UPDATED_AT 2014-11-17

RUN apt-get update

RUN apt-get install -y \
    openjdk-6-jre \
    wget

RUN wget https://download.elasticsearch.org/elasticsearch/elasticsearch/elasticsearch-0.90.7.deb \
    && dpkg -i elasticsearch-0.90.7.deb \
    && rm elasticsearch-0.90.7.deb

EXPOSE 9200

CMD /usr/share/elasticsearch/bin/elasticsearch -f -Des.http.port=9200 -Des.cluster.name=testing
