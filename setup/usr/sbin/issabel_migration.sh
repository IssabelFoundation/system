#!/bin/bash
#
# Copyright (C) 2017 Issabel Foundation
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either
# version 2 of the License, or (at your option) any later
# version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software Foundation,
# Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.

MYSQLPWD=$(cat /etc/issabel.conf  | grep mysqlrootpwd | cut -d"=" -f2)
DATADIR="/var/spool/issabel_migration.$(date +%s)"
TEMPDB=migration_asterisk_$RANDOM
#DATADIR="/var/spool/issabel_migration"
#BACKUPFILE=$1
PARSED_OPTIONS=$(getopt -n "$0"  -o dhb: --long "dadhi,help,backup-file:"  -- "$@")
alias cp=cp
alias mv=mv

function print_usage {
    echo "Usage:"
    echo "$0 [OPTIONS]"
    echo "OPTIONS:"
    echo "-d --dahdi: Restore DAHDI files"
    echo "-b --backup-file: Backup file to restore"
    echo "-h --help: Show help"
    exit 1
}

function open_backup_file {
    if ! [ -s $BACKUPFILE ]
    then
        echo No file to restore
        exit 1
    fi
    if [ "$BACKUPFILE" == "" ]
    then
        echo No backup file in arguments
        exit 1
    fi
    mkdir -p $DATADIR
    tar -xf $BACKUPFILE -C $DATADIR
    if [ ! -d $DATADIR/backup ]
    then
        mv $DATADIR/backup* /$DATADIR/backup
    fi
    cd $DATADIR/backup
    if [ -f $DATADIR/backup/mysqldb_asterisk.tgz ]
        then
    tar -xzf mysqldb_asterisk.tgz 2>&1 >/dev/null
    fi
    if [ -f $DATADIR/backup/mysql_mysql.tgz ]
        then
    tar -xzf mysql_mysql.tgz 2>&1 >/dev/null
    fi
    if [ -f $DATADIR/backup/endpointconfig_mysql.tgz ]
        then
    tar -xzf endpointconfig_mysql.tgz 2>&1 >/dev/null
    fi
    if [ -f $DATADIR/backup/roundcubedb_mysql.tgz ]
        then
    tar -xzf roundcubedb_mysql.tgz 2>&1 >/dev/null
    fi
    if [ -f $DATADIR/backup/meetme_mysql.tgz ]
        then
    tar -xzf meetme_mysql.tgz 2>&1 >/dev/null
    fi
}

function restore_asterisksql {
    if ! [ -f $DATADIR/backup/mysqldb_asterisk/asterisk.sql ]
    then
        return 1
    fi
    sed -i -e s/freepbx_settings/issabelpbx_settings/g $DATADIR/backup/mysqldb_asterisk/asterisk.sql
    sed -i -e s/freepbx_log/issabelpbx_log/g $DATADIR/backup/mysqldb_asterisk/asterisk.sql    
    mysql -uroot -p$MYSQLPWD asterisk < $DATADIR/backup/mysqldb_asterisk/asterisk.sql
    echo "update issabelpbx_settings set value='http://cloud.issabel.org,http://cloud2.issabel.org',defaultval='http://cloud.issabel.org,http://cloud2.issabel.org' where keyword='MODULE_REPO';" | mysql -uroot -p$MYSQLPWD asterisk
    if ! [ -f $DATADIR/backup/mysqldb_asterisk/asteriskcdrdb.sql ] 
        then
                return 1
        fi
    mysql -uroot -p$MYSQLPWD asteriskcdrdb < $DATADIR/backup/mysqldb_asterisk/asteriskcdrdb.sql
}

function restore_asteriskfiles {
    if ! [ -f $DATADIR/backup/etc.asterisk.tgz ]
    then
                return 1
        fi
    tar --exclude='manager.conf' --exclude='cdr_mysql.conf' --exclude='cbmysql.conf' -xzf $DATADIR/backup/etc.asterisk.tgz --strip-components=1 -C /etc/asterisk --wildcards "*_custom.conf" 2>&1 >/dev/null
    if [ "$RESTORE_DAHDI" != "1" ]
    then
        for i in $(ls $DATADIR/*dahdi*conf.pre)
        do
            cp -fp $i /etc/asterisk/$(basename $i .pre)
        done
    fi
}

function restore_sqlite_dbs {
    #REVISAR: creo que menu.db no va
    rm -f $DATADIR/backup/menu.db
    if [ -f $DATADIR/backup/acl.db ]; then
        mv $DATADIR/backup/acl.db $DATADIR/backup/acl.db.bkp
    fi
    ADMINPWD=$(sqlite3 /var/www/db/acl.db "select md5_password from acl_user where id=1")
    for i in $(ls $DATADIR/backup/*.db 2>/dev/null)
    do
        cp -bfp $i /var/www/db/
    done
    chown -R asterisk:asterisk /var/www/db
    sqlite3 /var/www/db/acl.db "update acl_user set md5_password='$ADMINPWD' where id=1"
    mysql -uroot -p$MYSQLPWD asterisk -e "UPDATE ampusers SET password_sha1 = sha1('$ADMINPWD') WHERE username='admin'"
}

function restore_sounds {
    if ! [ -f $DATADIR/backup/var.lib.asterisk.sounds.custom.tgz ]
    then
                return 1
        fi
    tar -xzf $DATADIR/backup/var.lib.asterisk.sounds.custom.tgz --strip-components=1 -C /var/lib/asterisk/sounds/custom 2>&1 >/dev/null
}

function restore_astdb {
    if ! [ -f $DATADIR/backup/astdb.sqlite3 ]
    then
                return 1
        fi
    cp -fp $DATADIR/backup/astdb.sqlite3 /var/lib/asterisk/
}

function restore_moh {
    if [ -f $DATADIR/backup/var.lib.asterisk.mohmp3.tgz -a -d /var/lib/asterisk/mohmp3 ]; then
        tar -xzf $DATADIR/backup/var.lib.asterisk.mohmp3.tgz --strip-components=1 -C /var/lib/asterisk/mohmp3 2>&1 >/dev/null
    fi

    if [ -f $DATADIR/backup/var.lib.asterisk.moh.tgz -a -d /var/lib/asterisk/moh ]; then
        tar -xzf $DATADIR/backup/var.lib.asterisk.moh.tgz --strip-components=1 -C /var/lib/asterisk/moh 2>&1 >/dev/null
    fi
}

function restore_endpoint {
    if ! [ -f $DATADIR/backup/tftpboot.tgz ]; then
        return 1
    fi

    if ! [ -d '/tftpboot' ]; then
        return 1
    fi

    tar -xzf $DATADIR/backup/tftpboot.tgz --strip-components=1 -C /tftpboot 2>&1 >/dev/null
    if ! [ -f $DATADIR/backup/endpointconfig.sql ]; then
        return 1
    fi
    mysql -uroot -p$MYSQLPWD endpointconfig < $DATADIR/backup/endpointconfig.sql 
}

function restore_faxes {
    if ! [ -f $DATADIR/backup/var.www.faxes.tgz ]
    then
                return 1
        fi
    tar -xzf $DATADIR/backup/var.www.faxes.tgz --strip-components=1 -C /var/www/faxes 2>&1 >/dev/null
}

function restore_mail {
    if ! [ -f $DATADIR/backup/var.spool.imap.tgz ]
    then
                return 1
        fi
    tar -xzf $DATADIR/backup/var.spool.imap.tgz --strip-components=1 -C /var/spool/imap 2>&1 >/dev/null
    if ! [ -f $DATADIR/backup/roundcubedb.sql ]
    then
                return 1
        fi
    mysql -uroot -p$MYSQLPWD roundcubedb < $DATADIR/backup/roundcubedb.sql
}

function restore_mysqldb {
    if ! [ -f $DATADIR/backup/mysql.sql ]
    then
                return 1
        fi
    mysql -uroot -p$MYSQLPWD mysql $DATADIR/backup/mysql.sql
}
function restore_dahdi {
    if ! [ -f $DATADIR/backup/etc.dahdi.tgz ]
        then
                return 1
        fi
        tar -xzf $DATADIR/backup/etc.dahdi.tgz --strip-components=1 -C /etc/dahdi 2>&1 >/dev/null
}
function restore_monitor {
        if ! [ -f $DATADIR/backup/var.spool.asterisk.monitor.tgz ]
        then
                return 1
        fi
        tar -xzf $DATADIR/backup/var.spool.asterisk.monitor.tgz --strip-components=1 -C /var/spool/asterisk/monitor 2>&1 >/dev/null
}
function restore_voicemail {
        if ! [ -f $DATADIR/backup/var.spool.asterisk.voicemail.tgz ]
        then
                return 1
        fi
        tar -xzf $DATADIR/backup/var.spool.asterisk.voicemail.tgz --strip-components=1 -C /var/spool/asterisk/voicemail 2>&1 >/dev/null
}

function check_versions {
    if grep -qE 'id="elastix" ver="4|id="elastix" ver="2.5|id="issabelpbx" ver="2.11' $DATADIR/backup/versions.xml
    then
            echo Elastix Version OK
    else
            echo Wrong Elastix Version or Backup File
            exit 1
    fi

    if grep -qE 'id="freepbx" ver="2.11|id="issabelpbx" ver="2.11' $DATADIR/backup/versions.xml
    then
            echo FreePBX Version OK
    else
            echo Wrong FreePBX Version or Backup File
            exit 1
    fi
}

function parse_args {
    #PARSED_OPTIONS=$(getopt -n "$0"  -o dhb: --long "dadhi,help,backup-file:"  -- "$@")
    #Bad arguments, something has gone wrong with the getopt command.
    if [ $? -ne 0 ];
    then
        echo ERROR getting args
          exit 1
    fi
    eval set -- "$PARSED_OPTIONS"

    while true
    do
          case "$1" in
            -h|--help)
            print_usage
                 shift;;
            -d|--dahdi)
            RESTORE_DAHDI=1
              shift;;
            -b|--backup-file)
                  if [ -n "$2" ];
                  then
                BACKUPFILE=$2
                  fi
                  shift 2;;
            --)
                  shift
                  break;;
            *) 
            echo "Invalid option $1"
            print_usage
            exit 1 ;;
          esac
    done
}

function keep_files {
    for i in $(ls /etc/asterisk/*dahdi*conf)
    do
        cp  -p $i $DATADIR/$(basename $i).pre
    done
    mysqldump --opt -uroot -p$MYSQLPWD asterisk > $DATADIR/asterisk.sql.pre
        mysqldump --opt -uroot -p$MYSQLPWD asteriskcdrdb > $DATADIR/asteriskcdrdb.sql.pre
    cd /
    tar -czf $DATADIR/etc.asterisk.tgz.pre etc/asterisk 2>&1 >/dev/null
    tar -czf $DATADIR/etc.dahdi.tgz.pre etc/dahdi 2>&1 >/dev/null
    tar -czf $DATADIR/etc.dahdi.tgz.pre etc/dahdi 2>&1 >/dev/null
    tar -czf $DATADIR/var.lib.asterisk.sounds.custom.tgz.pre var/lib/asterisk/sounds/custom 2>&1 >/dev/null
    if [ -d '/tftpboot' ]; then
        tar -czf $DATADIR/tftpboot.tgz.pre tftpboot 2>&1 >/dev/null
    fi
}

function update_acl {
# Importar users distintos a admin
    sqlite3 $DATADIR/backup/acl.db.bkp "select name,description,md5_password,extension from acl_user where name<>'admin'" | awk -F\| '{ print "INSERT INTO acl_user (name,description,md5_password,extension) VALUES (\"" $1"\",\""$2"\",\""$3"\",\""$4"\");"}' | sqlite3 /var/www/db/acl.db
# Relacion user/group
    sqlite3 $DATADIR/backup/acl.db.bkp "select id_user,id_group from acl_membership where id_user>1" | awk -F\| '{ print "INSERT INTO acl_membership (id_user,id_group) VALUES (\""$1"\",\""$2"\");"}' | sqlite3 /var/www/db/acl.db
# Creo grupos custom, sin asignarle modulos
    sqlite3 $DATADIR/backup/acl.db.bkp "select name,description from acl_group where id>3" | awk -F\| '{ print "INSERT INTO acl_group (name,description) VALUES (\""$1"\",\""$2"\");"}' | sqlite3 /var/www/db/acl.db
}

function restore_asterisktempsql {
        if ! [ -f $DATADIR/backup/mysqldb_asterisk/asterisk.sql ]
        then
        NOSQLFILE=1
                return 1
        fi
        MYSQLFILE=$DATADIR/backup/mysqldb_asterisk/asterisk.sql
        mysql -uroot -p$MYSQLPWD -e "CREATE DATABASE $TEMPDB;"
        sed -i '/INSERT INTO `cel`/d' $MYSQLFILE
        sed -i '/INSERT INTO `endpoint_basefiles`/d' $MYSQLFILE
        sed -i '/INSERT INTO `soundlang_prompts`/d' $MYSQLFILE
        mysql -uroot -p$MYSQLPWD $TEMPDB < $MYSQLFILE
}

function restore_sqlfromtemp {
    (
    if [ "NOSQLFILE" == "1" ]
    then
        return 1
    fi
    TABLES="announcement callback callrecording callrecording_module cidlookup cidlookup_incoming custom_extensions dahdi dahdichandids daynight devices disa extensions fax_details fax_incoming fax_users featurecodes iax iaxsettings incoming findmefollow indications_zonelist ivr_details ivr_entries language_incoming languages manager meetme miscapps miscdests outbound_route_patterns outbound_route_sequence outbound_route_trunks outbound_routes outroutemsg paging_autoanswer paging_config paging_groups parkplus pinset_usage pinsets queueprio queues_config queues_details recordings ringgroups sip sipsettings timeconditions timegroups_details timegroups_groups trunk_dialpatterns trunks users vmblast vmblast_groups voicemail_admin customcontexts_contexts customcontexts_contexts_list customcontexts_includes customcontexts_includes_list"
    IFS=' ' read -r -a TABLE_ARRAY <<< "$TABLES"
    for TABLE in "${TABLE_ARRAY[@]}"; do
        TABLE_COUNT=$(mysql -NB -uroot -p$MYSQLPWD -e "SELECT COUNT(TABLE_NAME) FROM information_schema.TABLES WHERE TABLE_SCHEMA LIKE 'asterisk' AND TABLE_TYPE LIKE 'BASE TABLE' AND TABLE_NAME = '$TABLE'")
        if [ "$TABLE_COUNT" = "1" ]; then
            echo "Importing $TABLE"
            COMMON_FIELDS=$(mysql -NB -uroot -p$MYSQLPWD -e "SELECT COLUMN_NAME,count(*) AS common FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA IN ('asterisk','$TEMPDB') AND TABLE_NAME='$TABLE' group by 1 having common=2" | cut -f 1 | xargs | sed 's/ /\`,\`/'g)
            mysql -uroot -p$MYSQLPWD $TEMPDB -e "TRUNCATE TABLE asterisk.$TABLE;"
            mysql -uroot -p$MYSQLPWD $TEMPDB -e "INSERT INTO asterisk.$TABLE (\`$COMMON_FIELDS\`) SELECT \`$COMMON_FIELDS\` FROM $TABLE;"
        else
            echo "Skip importing table $TABLE as it does not exist on destination" 
        fi
    done
    ) &> $DATADIR/import.log 
}

parse_args
echo "--PLEASE WAIT UNTIL PAGE RELOADS--"
echo " "
echo -e "Openning backup file... \c"
if open_backup_file
then 
    echo OK
else
    echo SKIP
fi
check_versions
echo -e "Backing up actual configuaration to $DATADIR... \c"
keep_files
cp -p /var/www/html/index.php $DATADIR
echo OK
echo -e "Creating temp DB $TEMPDB (this may take a long time)... \c"
restore_asterisktempsql
echo "OK"
echo -e "Restoring Asterisk DB... \c"
#if restore_asterisksql
if restore_sqlfromtemp
then
    echo OK
else 
    echo SKIP
fi
echo -e "Restoring Asterisk files... \c"
if restore_asteriskfiles
then
    echo OK
else 
    echo SKIP
fi
echo -e "Restoring Web DBs... \c"
if restore_sqlite_dbs
then
    echo OK
else
    echo SKIP
fi
#insert new modules from menu.db
update_acl
echo -e "Restoring Asterisk Sound files... \c"
if restore_sounds
then
    echo OK
else
    echo SKIP
fi
echo -e "Restoring astdb... \c"
if restore_astdb
then
    echo OK
else
    echo SKIP
fi
echo -e "Restoring MOH files... \c"
if restore_moh
then
    echo OK
else
    echo SKIP
fi
echo -e "Restoring Enpoint configs... \c"
if restore_endpoint
then
    echo OK
else
    echo SKIP
fi
echo -e "Restoring Faxes... \c"
if restore_faxes
then
    echo OK
else
    echo SKIP
fi
echo -e "Restoring Emails... \c"
if restore_mail
then
    echo OK
else
    echo SKIP
fi
if [ "$RESTORE_DAHDI" == "1" ]
then
    restore_dahdi
fi
echo -e "Restoring Monitor files... \c"
if restore_monitor
then
    echo OK
else
    echo SKIP
fi
echo -e "Restoring Voicemail files... \c"
if restore_voicemail
then
    echo OK
else
    echo SKIP
fi
#update issabel.conf
AMIPWD=$(echo "select value from issabelpbx_settings where keyword = 'AMPMGRPASS' limit 1" | mysql -s -N -uroot -p$MYSQLPWD asterisk)
sed -i $(grep -n amiadminpwd /etc/issabel.conf|cut -f1 -d:)"s/.*/amiadminpwd=$AMIPWD/" /etc/issabel.conf
#restore_mysqldb
/usr/sbin/asterisk -rx "core restart now" 2>&1 > /dev/null
#trato de acomodar modulos de issabelPBX
/usr/sbin/amportal a ma delete fw_fop &> /dev/null
/usr/sbin/amportal a ma delete sipstation &> /dev/null
/usr/sbin/amportal a ma delete irc &> /dev/null
#/usr/sbin/amportal a ma upgradeall &> /dev/null

for count in {1..5}
do
    for i in $(/usr/sbin/amportal a ma list | grep -E 'Broken|Disabled' | cut -d" " -f1)
    do
        echo "Updating IssabelPBX module: $i"
        /usr/sbin/amportal a ma download $i &> /dev/null
        /usr/sbin/amportal a ma install $i &> /dev/null
        /usr/sbin/amportal a ma enable $i &> /dev/null
        cp -p $DATADIR/index.php /var/www/html/
        echo Done
    done
done
/usr/sbin/amportal a ma install customcontexts &> /dev/null
/usr/sbin/amportal a ma enable customcontexts &> /dev/null
su - asterisk /var/lib/asterisk/bin/retrieve_conf &> /dev/null
/usr/sbin/asterisk -rx "core reload" 2>$1 > /dev/null
cp -p $DATADIR/index.php /var/www/html/
rm -rf /$DATADIR/backup
mysql -uroot -p$MYSQLPWD -e "DROP DATABASE $TEMPDB"
/usr/sbin/amportal a r
