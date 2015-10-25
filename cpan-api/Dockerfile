FROM ubuntu:14.04.3

RUN apt-get update && apt-get install -y \
    curl \
    gcc \
    git \
    libcurl4-openssl-dev \
    libexpat1-dev \
    libxml2-dev \
    libgmp10-dev \
    make

RUN curl --silent https://raw.githubusercontent.com/miyagawa/cpanminus/1.7039/cpanm | perl - App::cpanminus
RUN cpanm Carton@v1.0.22

WORKDIR /app

RUN git clone https://github.com/CPAN-API/cpan-api.git /app/

# Command is specifyed twice, becase it does not work otherwise.
# (need to find out why and fix it)
RUN carton install --deployment || carton install --deployment

EXPOSE 5000

CMD ["carton", "exec", "plackup", "-p", "5000", "-r"]
