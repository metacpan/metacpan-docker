# OrePAN2

This is a dockerized version of perl module [OrePAN2](https://metacpan.org/release/OrePAN2).

First you need to build docker image:

    docker build --tag orepan2 .

And then you can use that image to create dakpan structure.

    docker run \
        --rm \
        --volume $(pwd)/darkpan:/darkpan \
        orepan2 \
        orepan2-inject Test::Whitespaces /darkpan

This command will download module Test::Whitespaces from the big CPAN and
place in at $(pwd)/darkpan Here the sample of what will be created:

    $ find $(pwd)/darkpan
    /Users/bessarabov/darkpan
    /Users/bessarabov/darkpan/authors
    /Users/bessarabov/darkpan/authors/id
    /Users/bessarabov/darkpan/authors/id/D
    /Users/bessarabov/darkpan/authors/id/D/DU
    /Users/bessarabov/darkpan/authors/id/D/DU/DUMMY
    /Users/bessarabov/darkpan/authors/id/D/DU/DUMMY/Test-Whitespaces-1.2.1.tar.gz
    /Users/bessarabov/darkpan/modules
    /Users/bessarabov/darkpan/modules/02packages.details.txt.gz
    /Users/bessarabov/darkpan/orepan2-cache.json

For more examples of using orepan2-inject see the [docs](https://metacpan.org/pod/distribution/OrePAN2/script/orepan2-inject)
