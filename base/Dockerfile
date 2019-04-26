ARG PERL_VERSION=5.28
FROM perl:${PERL_VERSION} AS build

WORKDIR /metacpan
COPY cpanfile cpanfile.snapshot /metacpan/

# CPM installations of dependencies does not install or run tests. This is
# because the modules themselves have been tested, and the metacpan use of the
# modules is tested by the test suite. Removing the tests, reduces the overall
# size of the images.
RUN apt-get update \
    && apt-get install -y libgmp-dev rsync \
    && cpanm App::cpm \
    && cpm install -g --without-test Carton \
    && cpm install -g --without-test

FROM perl:${PERL_VERSION}
COPY --from=build /usr/local/lib/perl5 /usr/local/lib/perl5
COPY --from=build /usr/local/bin /usr/local/bin
COPY wait-for-it.sh /
