#!/bin/sh

./bin/run bin/metacpan mapping --delete

/bin/partial-cpan-mirror.sh

./bin/run bin/metacpan release /CPAN/authors/id/
./bin/run bin/metacpan latest
./bin/run bin/metacpan author
