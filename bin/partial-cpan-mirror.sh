#!/bin/sh

MINICPAN=${MINICPAN:-$HOME/CPAN}
mkdir -p $MINICPAN

RSYNC='/usr/bin/rsync -av --delete --relative'
PATH='cpan-rsync.perl.org::CPAN'

$RSYNC $PATH/authors/id/L/LL/LLAP       $MINICPAN/
$RSYNC $PATH/authors/id/N/NE/NEILB      $MINICPAN/
$RSYNC $PATH/authors/id/O/OA/OALDERS    $MINICPAN/
$RSYNC $PATH/authors/id/P/PE/PERLER     $MINICPAN/
$RSYNC $PATH/authors/id/R/RW/RWSTAUNER  $MINICPAN/

$RSYNC $PATH/authors/0*                 $MINICPAN/
$RSYNC $PATH/modules/0*                 $MINICPAN/

$RSYNC $PATH/indices/mirrors.json       $MINICPAN/
