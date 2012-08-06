#!/bin/bash

BASEDIR=`pwd`

while read file; do
    echo $file
    perlcritic --profile $BASEDIR/.perlcriticrc $file
done < <( ( find $BASEDIR/bin -type f | grep -Ev 'distill_update|distill_schema'; find $BASEDIR/cgi -type f; find $BASEDIR/lib/perl5/Distill -type f ) | grep -v '.svn' )
