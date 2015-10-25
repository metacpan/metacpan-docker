# OrePAN2

This is a dockerized version of perl module
[OrePAN2](https://metacpan.org/release/OrePAN2).

First you need to build docker image:

    docker build --tag orepan2 .

And then you can use that image to create dakpan structure.

    docker run \
        --rm \
        --volume `pwd`/cpan:/cpan \
        orepan2 \
        carton exec orepan2-inject --author LOGIN Test::Whitespaces /cpan

This command will download module Test::Whitespaces from the big CPAN and
place in on your host machine. Here the sample of what will be created:

    $ find `pwd`/cpan
    /Users/bessarabov/cpan
    /Users/bessarabov/cpan/authors
    /Users/bessarabov/cpan/authors/id
    /Users/bessarabov/cpan/authors/id/L
    /Users/bessarabov/cpan/authors/id/L/LO
    /Users/bessarabov/cpan/authors/id/L/LO/LOGIN
    /Users/bessarabov/cpan/authors/id/L/LO/LOGIN/Test-Whitespaces-1.2.1.tar.gz
    /Users/bessarabov/cpan/modules
    /Users/bessarabov/cpan/modules/02packages.details.txt.gz
    /Users/bessarabov/cpan/orepan2-cache.json

For more examples of using orepan2-inject see the
[docs](https://metacpan.org/pod/distribution/OrePAN2/script/orepan2-inject).
