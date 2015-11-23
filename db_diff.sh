#!/bin/bash

function db_diff() {
    dump () {
      up=${1%%@*}; user=${up%%:*}; pass=${up##*:}; dbname=${1##*@};
      mysqldump --opt --compact --skip-extended-insert -u $user -p$pass $dbname $table > $2
    }
    cur_dir=$( dirname "${BASH_SOURCE[0]}" )

    [ -z "$1" -o -z "$2" ] && echo "Usage: db_diff [user1:pass1@dbname1] [user2:pass2@dbname2] [ignore_table1:ignore_table2...]" && return

    # Compare
    up=${1%%@*}; user=${up%%:*}; pass=${up##*:}; dbname=${1##*@};
    for table in `mysql -u $user -p$pass $dbname -N -e "show tables" --batch`; do
      if [ "`echo $3 | grep $table`" = "" ]; then
        echo "Comparing '$table'..."
        db1file=$(mktemp /tmp/db1.$table.XXXXXX.sql)
        db2file=$(mktemp /tmp/db2.$table.XXXXXX.sql)
        dump $1 $db1file
        dump $2 $db2file
        diff -up $db1file $db2file >> $(mktemp /tmp/result.$table.XXXXXX.sql)
        rm -f $db1file $db2file
      else
        echo "Ignored '$table'..."
      fi
    done
    echo "check results by reading /tmp/result.* files"
}

