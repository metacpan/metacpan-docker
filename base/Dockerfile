ARG PERL_VERSION=5.28
FROM perl:${PERL_VERSION} AS build

WORKDIR /metacpan
COPY cpanfile cpanfile.snapshot /metacpan/

FROM perl:${PERL_VERSION}
COPY --from=build /usr/local/lib/perl5 /usr/local/lib/perl5
COPY --from=build /usr/local/bin /usr/local/bin
COPY wait-for-it.sh /
