#!/bin/bash

BASEDIR=`pwd`

perl_tidy()
{
    local file="$1"

    echo $file
    perltidy -pro=$BASEDIR/.perltidyrc "$file" >"$file.tdy" || exit 1
    mv "$file.tdy" "$file"
}


while read file; do
    file_type=$( file -i "$file" | cut -d ' ' -f 2 )
    file_ext=$( echo "$file" | awk -F . '{ print $NF }' )

    case "$file_type" in
        'text/x-perl;')
            perl_tidy "$file"
            ;;
        'text/x-ruby;')
            rbeautify "$file"
            ;;
        *)
            if [ $file_ext == 'pm' ]; then
                perl_tidy "$file"
            fi
        ;;
    esac
done < <( find $BASEDIR/bin $BASEDIR/cgi $BASEDIR/lib/perl5/Distill -type f | grep -v '.svn' )
chmod +x $BASEDIR/bin/*
chmod +x $BASEDIR/cgi/*
