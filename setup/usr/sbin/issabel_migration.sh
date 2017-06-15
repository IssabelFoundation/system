#!/bin/bash
MYSQLPWD=$(cat /etc/issabel.conf  | grep mysqlrootpwd | cut -d"=" -f2)
DATADIR="/var/spool/issabel_migration.$(date +%s)"
#DATADIR="/var/spool/issabel_migration"
#BACKUPFILE=$1
PARSED_OPTIONS=$(getopt -n "$0"  -o dhb: --long "dadhi,help,backup-file:"  -- "$@")
alias cp=cp

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
	tar -xzf $DATADIR/backup/etc.asterisk.tgz --strip-components=1 -C /etc/asterisk 2>&1 >/dev/null
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
	ADMINPWD=$(sqlite3 /var/www/db/acl.db "select md5_password from acl_user where id=1")
	for i in $(ls $DATADIR/backup/*.db)
	do
		cp -fp $i /var/www/db/
	done
	chown -R asterisk:asterisk /var/www/db
	sqlite3 /var/www/db/acl.db "update acl_user set md5_password='$ADMINPWD'"
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
	if ! [ -f $DATADIR/backup/var.lib.asterisk.mohmp3.tgz ]
	then
                return 1
        fi
	tar -xzf $DATADIR/backup/var.lib.asterisk.mohmp3.tgz --strip-components=1 -C /var/lib/asterisk/mohmp3 2>&1 >/dev/null
	if ! [ -f $DATADIR/backup/var.lib.asterisk.moh.tgz ]
	then
                return 1
        fi
	tar -xzf $DATADIR/backup/var.lib.asterisk.moh.tgz --strip-components=1 -C /var/lib/asterisk/moh 2>&1 >/dev/null
}

function restore_endpoint {
	if ! [ -f $DATADIR/backup/tftpboot.tgz ]
	then
                return 1
        fi
	tar -xzf $DATADIR/backup/tftpboot.tgz --strip-components=1 -C /tftpboot 2>&1 >/dev/null
	if ! [ -f $DATADIR/backup/endpointconfig.sql ]
	then
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
	if grep -qE 'id="elastix" ver="4|id="elastix" ver="2.5' $DATADIR/backup/versions.xml
	then
        	echo Elastix Version OK
	else
       	 	echo Wrong Elastix Version or Backup File
        	exit 1
	fi

	if grep -q 'id="freepbx" ver="2.11' $DATADIR/backup/versions.xml
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
	tar -czf $DATADIR/tftpboot.tgz.pre tftpboot 2>&1 >/dev/null
}

function update_acl {
OLDIFS=$IFS
IFS=$'\n'
MODULES=$(sqlite3 /var/www/db/acl.db <<EOF
.mode insert acl_resource
attach database '/var/www/db/menu.db' AS 'menu';
select id,name from menu where id not in (select name from acl_resource) and type = 'module';
EOF
)
for i in $MODULES
do
	echo insert ${i/acl_resource/'acl_resource (name, description)'}
	sqlite3 /var/www/db/acl.db "${i/acl_resource/acl_resource (name, description)}"
done
	IFS=$OLDIFS
	INICIO=$(sqlite3 /var/www/db/acl.db "select id_resource from acl_group_permission order by id_resource desc limit 1")
	FIN=$(sqlite3 /var/www/db/acl.db "select id from acl_resource order by id desc limit 1")
	for i in $(seq $INICIO $FIN)
	do
        	sqlite3 /var/www/db/acl.db "insert into acl_group_permission (id_action, id_group, id_resource) VALUES(1,1,$i)"
	done
}

parse_args
echo -e "Openning backup file... \c"
if open_backup_file
then 
	echo OK
else
	echo FAIL
fi
check_versions
echo -e "Backing up actual configuaration... \c"
keep_files
echo OK
echo -e "Restoring Asterisk DB... \c"
if restore_asterisksql
then
	echo OK
else 
	echo FAIL
fi
echo -e "Restoring Asterisk files... \c"
if restore_asteriskfiles
then
        echo OK
else 
        echo FAIL
fi
echo -e "Restoring Web DBs... \c"
if restore_sqlite_dbs
then
        echo OK
else
        echo FAIL
fi
#insert new modules from menu.db
update_acl
echo -e "Restoring Asterisk Sound files... \c"
if restore_sounds
then
        echo OK
else
        echo FAIL
fi
echo -e "Restoring astdb... \c"
if restore_astdb
then
        echo OK
else
        echo FAIL
fi
echo -e "Restoring MOH files... \c"
if restore_moh
then
        echo OK
else
        echo FAIL
fi
echo -e "Restoring Enpoint configs... \c"
if restore_endpoint
then
        echo OK
else
        echo FAIL
fi
echo -e "Restoring Faxes... \c"
if restore_faxes
then
        echo OK
else
        echo FAIL
fi
echo -e "Restoring Emails... \c"
if restore_mail
then
        echo OK
else
        echo FAIL
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
        echo FAIL
fi
echo -e "Restoring Voicemail files... \c"
if restore_voicemail
then
        echo OK
else
        echo FAIL
fi
#update issabel.conf
AMIPWD=$(echo "select value from issabelpbx_settings where keyword = 'AMPMGRPASS' limit 1" | mysql -s -N -uroot -p$MYSQLPWD asterisk)
sed -i $(grep -n amiadminpwd /etc/issabel.conf|cut -f1 -d:)"s/.*/amiadminpwd=$AMIPWD/" /etc/issabel.conf
#restore_mysqldb
/usr/sbin/asterisk -rx "core restart now" 2>$1 > /dev/null
#trato de acomodar modulos de issabelPBX
/usr/sbin/amportal a ma delete fw_fop 2>$1 > /dev/null
/usr/sbin/amportal a ma delete sipstation 2>$1 > /dev/null
/usr/sbin/amportal a ma delete irc 2>$1 > /dev/null
/usr/sbin/amportal a ma upgradeall 2>$1 > /dev/null
for i in $(/usr/sbin/amportal a ma list | grep -E 'Broken|Disabled' | cut -d" " -f1)
do
	echo "Updating IssabelPBX module: $i"
	/usr/sbin/amportal a ma download $i 2>$1 > /dev/null
	/usr/sbin/amportal a ma install $i 2>$1 > /dev/null
	echo Done
done
su - asterisk /var/lib/asterisk/bin/retrieve_conf 2>$1 > /dev/null
/usr/sbin/asterisk -rx "core reload" 2>$1 > /dev/null
rm -rf /$DATADIR/backup
