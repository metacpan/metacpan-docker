# do not edit this file
# create etc/metacpan_local.pl instead
use FindBin;

{
    # ElasticSearch instance, can be either a single server
    # or an arrayref of servers
    es => 'elasticsearch:9200',
    # the port of the api server
    port => '5000',
    # log level
    level => 'info',
    # appender for Log4perl
    # default layout is "%d %p{1} %c: %m{chomp}%n"
    # can be overridden using the layout key
    # defining logger in metacpan_local.pl will
    # override and not append to this configuration
    logger => [{
        class => 'Log::Log4perl::Appender::File',
        filename => $FindBin::RealBin . '/../var/log/metacpan.log',
        syswrite => 1,
    }]
}