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
	mv $DATADIR/backup/acl.db $DATADIR/backup/acl.db.bkp
	ADMINPWD=$(sqlite3 /var/www/db/acl.db "select md5_password from acl_user where id=1")
	for i in $(ls $DATADIR/backup/*.db)
	do
		cp -fp $i /var/www/db/
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
        echo announcement
	mysql -uroot -p$MYSQLPWD $TEMPDB -e "TRUNCATE TABLE asterisk.announcement;"
	mysql -uroot -p$MYSQLPWD $TEMPDB -e "INSERT INTO asterisk.announcement SELECT announcement_id, description, recording_id, allow_skip, post_dest, return_ivr, noanswer, repeat_msg FROM announcement;"
	echo callback
	mysql -uroot -p$MYSQLPWD $TEMPDB -e "TRUNCATE TABLE asterisk.callback;"
        mysql -uroot -p$MYSQLPWD $TEMPDB -e "INSERT INTO asterisk.callback SELECT callback_id, description, callbacknum, destination, sleep, deptname FROM callback;"
	echo callrecording
	mysql -uroot -p$MYSQLPWD $TEMPDB -e "TRUNCATE TABLE asterisk.callrecording;"
        mysql -uroot -p$MYSQLPWD $TEMPDB -e "INSERT INTO asterisk.callrecording SELECT callrecording_id, callrecording_mode, description, dest FROM callrecording;"
	echo callrecording_module
	mysql -uroot -p$MYSQLPWD $TEMPDB -e "TRUNCATE TABLE asterisk.callrecording_module;"
        mysql -uroot -p$MYSQLPWD $TEMPDB -e "INSERT INTO asterisk.callrecording_module SELECT extension, cidnum, callrecording, display FROM callrecording_module;"
	echo cidlookup
	mysql -uroot -p$MYSQLPWD $TEMPDB -e "TRUNCATE TABLE asterisk.cidlookup;"
        mysql -uroot -p$MYSQLPWD $TEMPDB -e "INSERT INTO asterisk.cidlookup SELECT cidlookup_id, description, sourcetype, cache, deptname, http_host, http_port, http_username, http_password, http_path, http_query, mysql_host, mysql_dbname, mysql_query, mysql_username, mysql_password, mysql_charset, opencnam_account_sid, opencnam_auth_token FROM cidlookup;"
	echo cidlookup_incoming
	mysql -uroot -p$MYSQLPWD $TEMPDB -e "TRUNCATE TABLE asterisk.cidlookup_incoming;"
        mysql -uroot -p$MYSQLPWD $TEMPDB -e "INSERT INTO asterisk.cidlookup_incoming SELECT cidlookup_id, extension, cidnum FROM cidlookup_incoming;"	
	echo custom_extensions
	mysql -uroot -p$MYSQLPWD $TEMPDB -e "TRUNCATE TABLE asterisk.custom_extensions;"
        mysql -uroot -p$MYSQLPWD $TEMPDB -e "INSERT INTO asterisk.custom_extensions SELECT custom_exten, description, notes  FROM custom_extensions;"
	echo dahdi
	mysql -uroot -p$MYSQLPWD $TEMPDB -e "TRUNCATE TABLE asterisk.dahdi;"
        mysql -uroot -p$MYSQLPWD $TEMPDB -e "INSERT INTO asterisk.dahdi SELECT id, keyword, data, flags FROM dahdi;"
	echo dahdichandids
	mysql -uroot -p$MYSQLPWD $TEMPDB -e "TRUNCATE TABLE asterisk.dahdichandids;"
        mysql -uroot -p$MYSQLPWD $TEMPDB -e "INSERT INTO asterisk.dahdichandids SELECT channel, description, did FROM dahdichandids;"
	echo daynight
	mysql -uroot -p$MYSQLPWD $TEMPDB -e "TRUNCATE TABLE asterisk.daynight;"
        mysql -uroot -p$MYSQLPWD $TEMPDB -e "INSERT INTO asterisk.daynight SELECT ext, dmode, dest FROM daynight;"
	echo devices
	mysql -uroot -p$MYSQLPWD $TEMPDB -e "TRUNCATE TABLE asterisk.devices;"
        mysql -uroot -p$MYSQLPWD $TEMPDB -e "INSERT INTO asterisk.devices SELECT id, tech, dial, devicetype, user, description, emergency_cid FROM devices;"
	sleep 1
	mysql -uroot -p$MYSQLPWD asterisk -e "update devices set tech = REPLACE(tech,'pjsip','sip') where tech = 'pjsip';"
	mysql -uroot -p$MYSQLPWD asterisk -e "update devices set dial = REPLACE(dial,'PJSIP','SIP') where dial like 'PJSIP%';"
	echo disa
	mysql -uroot -p$MYSQLPWD $TEMPDB -e "TRUNCATE TABLE asterisk.disa;"
        mysql -uroot -p$MYSQLPWD $TEMPDB -e "INSERT INTO asterisk.disa SELECT disa_id, displayname, pin, cid, context, digittimeout, resptimeout, needconf, hangup, keepcid FROM disa;"
	echo extensions
	mysql -uroot -p$MYSQLPWD $TEMPDB -e "TRUNCATE TABLE asterisk.extensions;"
        mysql -uroot -p$MYSQLPWD $TEMPDB -e "INSERT INTO asterisk.extensions SELECT context, extension, priority, application, args, descr, flags FROM extensions;"
	echo faxes
	mysql -uroot -p$MYSQLPWD $TEMPDB -e "TRUNCATE TABLE asterisk.fax_details;"
        mysql -uroot -p$MYSQLPWD $TEMPDB -e "INSERT INTO asterisk.fax_details SELECT * FROM fax_details;"
	mysql -uroot -p$MYSQLPWD $TEMPDB -e "TRUNCATE TABLE asterisk.fax_incoming;"
        mysql -uroot -p$MYSQLPWD $TEMPDB -e "INSERT INTO asterisk.fax_incoming SELECT cidnum, extension, detection, detectionwait,destination, legacy_email FROM fax_incoming;"
	mysql -uroot -p$MYSQLPWD $TEMPDB -e "TRUNCATE TABLE asterisk.fax_users;"
        mysql -uroot -p$MYSQLPWD $TEMPDB -e "INSERT INTO asterisk.fax_users SELECT user, faxenabled, faxemail, faxattachformat FROM fax_users;"
	echo featurescodes
	mysql -uroot -p$MYSQLPWD $TEMPDB -e "UPDATE asterisk.featurecodes prod, featurecodes mig SET prod.customcode=mig.customcode WHERE mig.featurename = prod.featurename and mig.customcode <> '';"
	mysql -uroot -p$MYSQLPWD $TEMPDB -e "UPDATE asterisk.featurecodes prod, featurecodes mig SET prod.enabled=mig.enabled WHERE mig.featurename = prod.featurename and mig.enabled <> prod.enabled;"
	#Settings TODO
	#elect mig.keyword, mig.value from freepbx_settings mig, asterisk.issabelpbx_settings prod where prod.keyword = mig.keyword and prod.value <> mig.value and mig.value NOT REGEXP 'freepbx|angoma|cxpanel' and mig.keyword NOT REGEXP 'ast|http|moduleadmin|authtype|useresmwi|ampmgrpass|cdrdbname|disable_css_autogen';
	#Globals TODO
	echo iax
	mysql -uroot -p$MYSQLPWD $TEMPDB -e "TRUNCATE TABLE asterisk.iax;"
        mysql -uroot -p$MYSQLPWD $TEMPDB -e "INSERT INTO asterisk.iax SELECT id, keyword, data, flags FROM iax;"
	mysql -uroot -p$MYSQLPWD $TEMPDB -e "TRUNCATE TABLE asterisk.iaxsettings;"
        mysql -uroot -p$MYSQLPWD $TEMPDB -e "INSERT INTO asterisk.iaxsettings SELECT keyword, data, seq, type FROM iaxsettings;"
	echo incoming
	mysql -uroot -p$MYSQLPWD $TEMPDB -e "TRUNCATE TABLE asterisk.incoming;"
        mysql -uroot -p$MYSQLPWD $TEMPDB -e "INSERT INTO asterisk.incoming SELECT cidnum, extension, destination, faxexten, faxemail, answer, wait, privacyman, alertinfo, ringing, mohclass, description, grppre, delay_answer, pricid, pmmaxretries,  pmminlength FROM incoming;"
	echo findmefollow
	mysql -uroot -p$MYSQLPWD $TEMPDB -e "TRUNCATE TABLE asterisk.findmefollow;"
        mysql -uroot -p$MYSQLPWD $TEMPDB -e "INSERT INTO asterisk.findmefollow SELECT grpnum, strategy, grptime, grppre, grplist, annmsg_id, postdest, dring, remotealert_id, needsconf, toolate_id, pre_ring, ringing FROM findmefollow;"
	#indications_zonelist TODO
	echo ivr_details
	mysql -uroot -p$MYSQLPWD $TEMPDB -e "TRUNCATE TABLE asterisk.ivr_details;"
        mysql -uroot -p$MYSQLPWD $TEMPDB -e "INSERT INTO asterisk.ivr_details SELECT id, name, description, announcement, directdial, invalid_loops, invalid_retry_recording, invalid_destination, invalid_recording, retvm, timeout_time,  timeout_recording, timeout_retry_recording, timeout_destination, timeout_loops, timeout_append_announce, invalid_append_announce, '0', '0' FROM ivr_details;"
	echo ivr_entries
	mysql -uroot -p$MYSQLPWD $TEMPDB -e "TRUNCATE TABLE asterisk.ivr_entries;"
	mysql -uroot -p$MYSQLPWD $TEMPDB -e "ALTER TABLE asterisk.ivr_entries MODIFY dest varchar(200);"
        mysql -uroot -p$MYSQLPWD $TEMPDB -e "INSERT INTO asterisk.ivr_entries SELECT ivr_id, selection, dest, ivr_ret FROM ivr_entries;"
	echo language_incoming
	mysql -uroot -p$MYSQLPWD $TEMPDB -e "TRUNCATE TABLE asterisk.language_incoming;"
        mysql -uroot -p$MYSQLPWD $TEMPDB -e "INSERT INTO asterisk.language_incoming SELECT extension, cidnum, language FROM language_incoming;"
	echo languages
	mysql -uroot -p$MYSQLPWD $TEMPDB -e "TRUNCATE TABLE asterisk.languages;"
        mysql -uroot -p$MYSQLPWD $TEMPDB -e "INSERT INTO asterisk.languages SELECT language_id, lang_code, description, dest FROM languages;"
	echo manager
	mysql -uroot -p$MYSQLPWD $TEMPDB -e "TRUNCATE TABLE asterisk.manager;"
        mysql -uroot -p$MYSQLPWD $TEMPDB -e "INSERT INTO asterisk.manager SELECT manager_id, name, secret, deny, permit, 'read', 'write' FROM manager WHERE name NOT REGEXP 'admin|cxpanel';"
	echo meetme
	mysql -uroot -p$MYSQLPWD $TEMPDB -e "TRUNCATE TABLE asterisk.meetme;"
        mysql -uroot -p$MYSQLPWD $TEMPDB -e "INSERT INTO asterisk.meetme SELECT exten, options, userpin, adminpin, description, joinmsg_id, music, users FROM meetme;"
	echo miscapps
	mysql -uroot -p$MYSQLPWD $TEMPDB -e "TRUNCATE TABLE asterisk.miscapps;"
        mysql -uroot -p$MYSQLPWD $TEMPDB -e "INSERT INTO asterisk.miscapps SELECT miscapps_id, ext, description, dest FROM miscapps;"
	echo miscdests
	mysql -uroot -p$MYSQLPWD $TEMPDB -e "TRUNCATE TABLE asterisk.miscdests;"
        mysql -uroot -p$MYSQLPWD $TEMPDB -e "INSERT INTO asterisk.miscdests SELECT id, description, destdial FROM miscdests;" 
	echo outbound_route_patterns
	mysql -uroot -p$MYSQLPWD $TEMPDB -e "TRUNCATE TABLE asterisk.outbound_route_patterns;"
        mysql -uroot -p$MYSQLPWD $TEMPDB -e "INSERT INTO asterisk.outbound_route_patterns SELECT route_id, match_pattern_prefix, match_pattern_pass, match_cid, prepend_digits FROM outbound_route_patterns;"
	echo outbound_route_sequence
	mysql -uroot -p$MYSQLPWD $TEMPDB -e "TRUNCATE TABLE asterisk.outbound_route_sequence;"
        mysql -uroot -p$MYSQLPWD $TEMPDB -e "INSERT INTO asterisk.outbound_route_sequence SELECT route_id, seq FROM outbound_route_sequence;"
	echo outbound_route_trunks
	mysql -uroot -p$MYSQLPWD $TEMPDB -e "TRUNCATE TABLE asterisk.outbound_route_trunks;"
        mysql -uroot -p$MYSQLPWD $TEMPDB -e "INSERT INTO asterisk.outbound_route_trunks SELECT route_id, trunk_id, seq FROM outbound_route_trunks;"
	echo outbound_routes
	mysql -uroot -p$MYSQLPWD $TEMPDB -e "TRUNCATE TABLE asterisk.outbound_routes;"
        mysql -uroot -p$MYSQLPWD $TEMPDB -e "INSERT INTO asterisk.outbound_routes SELECT route_id, name, outcid, outcid_mode, password, emergency_route, intracompany_route, mohclass, time_group_id, dest FROM outbound_routes;"
	echo outroutemsg
	mysql -uroot -p$MYSQLPWD $TEMPDB -e "TRUNCATE TABLE asterisk.outroutemsg;"
        mysql -uroot -p$MYSQLPWD $TEMPDB -e "INSERT INTO asterisk.outroutemsg SELECT keyword, data FROM outroutemsg;"
	echo paging_autoanswer
	mysql -uroot -p$MYSQLPWD $TEMPDB -e "TRUNCATE TABLE asterisk.paging_autoanswer;"
        mysql -uroot -p$MYSQLPWD $TEMPDB -e "INSERT INTO asterisk.paging_autoanswer SELECT useragent, var, setting FROM paging_autoanswer;"
	echo paging_config
	mysql -uroot -p$MYSQLPWD $TEMPDB -e "TRUNCATE TABLE asterisk.paging_config;"
        mysql -uroot -p$MYSQLPWD $TEMPDB -e "INSERT INTO asterisk.paging_config SELECT  page_group, force_page, duplex, description FROM paging_config;"
	echo paging_groups
	mysql -uroot -p$MYSQLPWD $TEMPDB -e "TRUNCATE TABLE asterisk.paging_groups;"
        mysql -uroot -p$MYSQLPWD $TEMPDB -e "INSERT INTO asterisk.paging_groups SELECT page_number, ext FROM paging_groups;"
	echo parkplus
	mysql -uroot -p$MYSQLPWD $TEMPDB -e "TRUNCATE TABLE asterisk.parkplus;"
        mysql -uroot -p$MYSQLPWD $TEMPDB -e "INSERT INTO asterisk.parkplus SELECT id, defaultlot, type, name, parkext, parkpos, numslots, parkingtime, parkedmusicclass, generatefc, generatehints, findslot, parkedplay, parkedcalltransfers, parkedcallreparking, alertinfo, cidpp, autocidpp, announcement_id, comebacktoorigin, dest FROM parkplus;"
	echo pinset_usage
	mysql -uroot -p$MYSQLPWD $TEMPDB -e "TRUNCATE TABLE asterisk.pinset_usage;"
        mysql -uroot -p$MYSQLPWD $TEMPDB -e "INSERT INTO asterisk.pinset_usage SELECT pinsets_id, dispname, foreign_id FROM pinset_usage;"
	echo pinsets
	mysql -uroot -p$MYSQLPWD $TEMPDB -e "TRUNCATE TABLE asterisk.pinsets;"
        mysql -uroot -p$MYSQLPWD $TEMPDB -e "INSERT INTO asterisk.pinsets SELECT pinsets_id, passwords, description, addtocdr, deptname FROM pinsets;"
	echo queueprio
	mysql -uroot -p$MYSQLPWD $TEMPDB -e "TRUNCATE TABLE asterisk.queueprio;"
        mysql -uroot -p$MYSQLPWD $TEMPDB -e "INSERT INTO asterisk.queueprio SELECT queueprio_id, queue_priority, description, dest FROM queueprio;"
	echo queues_config
	mysql -uroot -p$MYSQLPWD $TEMPDB -e "TRUNCATE TABLE asterisk.queues_config;"
        mysql -uroot -p$MYSQLPWD $TEMPDB -e "INSERT INTO asterisk.queues_config(extension, descr, grppre, alertinfo, ringing, maxwait, password, ivr_id, dest, cwignore, qregex, agentannounce_id, joinannounce_id, queuewait, use_queue_context, togglehint, qnoanswer, callconfirm, callconfirm_id,  monitor_type, monitor_heard, monitor_spoken, callback_id) SELECT extension, descr, grppre, alertinfo, ringing, maxwait, password, ivr_id, dest, cwignore, qregex, agentannounce_id, joinannounce_id, queuewait, use_queue_context, togglehint, qnoanswer, callconfirm, callconfirm_id,  monitor_type, monitor_heard, monitor_spoken, callback_id FROM queues_config;"
	echo queues_details
	mysql -uroot -p$MYSQLPWD $TEMPDB -e "TRUNCATE TABLE asterisk.queues_details;"
        mysql -uroot -p$MYSQLPWD $TEMPDB -e "INSERT INTO asterisk.queues_details SELECT id, keyword, data, flags FROM queues_details;"
	echo recordings
	mysql -uroot -p$MYSQLPWD $TEMPDB -e "TRUNCATE TABLE asterisk.recordings;"
        mysql -uroot -p$MYSQLPWD $TEMPDB -e "INSERT INTO asterisk.recordings SELECT id, displayname, filename, description, fcode, fcode_pass FROM recordings;"
	echo ringgroups
	mysql -uroot -p$MYSQLPWD $TEMPDB -e "TRUNCATE TABLE asterisk.ringgroups;"
        mysql -uroot -p$MYSQLPWD $TEMPDB -e "INSERT INTO asterisk.ringgroups SELECT grpnum, strategy, grptime, grppre, grplist,  annmsg_id, postdest, description, alertinfo, remotealert_id, needsconf, toolate_id, ringing, cwignore, cfignore, cpickup, recording FROM ringgroups;"
	echo sip
	mysql -uroot -p$MYSQLPWD $TEMPDB -e "TRUNCATE TABLE asterisk.sip;"
        mysql -uroot -p$MYSQLPWD $TEMPDB -e "INSERT INTO asterisk.sip SELECT id, keyword, data, flags FROM sip;"
	sleep 1
	mysql -uroot -p$MYSQLPWD asterisk -e "update sip set data = REPLACE(data,'PJSIP','SIP') where keyword = 'dial' and data like 'PJSIP%';"
	mysql -uroot -p$MYSQLPWD asterisk -e "update sip set data = REPLACE(data,'chan_pjsip','chan_sip') where keyword = 'sipdriver' and data like 'chan_pjsip';"
	echo sipsettings
	mysql -uroot -p$MYSQLPWD $TEMPDB -e "TRUNCATE TABLE asterisk.sipsettings;"
        mysql -uroot -p$MYSQLPWD $TEMPDB -e "INSERT INTO asterisk.sipsettings SELECT keyword, data, seq, type FROM sipsettings;"
	echo timeconditions
	mysql -uroot -p$MYSQLPWD $TEMPDB -e "TRUNCATE TABLE asterisk.timeconditions;"
        mysql -uroot -p$MYSQLPWD $TEMPDB -e "INSERT INTO asterisk.timeconditions SELECT timeconditions_id, displayname, time, truegoto, falsegoto, deptname, generate_hint, priority FROM timeconditions;"
	echo timegroups_details
	mysql -uroot -p$MYSQLPWD $TEMPDB -e "TRUNCATE TABLE asterisk.timegroups_details;"
        mysql -uroot -p$MYSQLPWD $TEMPDB -e "INSERT INTO asterisk.timegroups_details SELECT id, timegroupid, time FROM timegroups_details;"
	echo timegroups_groups
	mysql -uroot -p$MYSQLPWD $TEMPDB -e "TRUNCATE TABLE asterisk.timegroups_groups;"
        mysql -uroot -p$MYSQLPWD $TEMPDB -e "INSERT INTO asterisk.timegroups_groups SELECT id, description FROM timegroups_groups;"
	echo trunk_dialpatterns
	mysql -uroot -p$MYSQLPWD $TEMPDB -e "TRUNCATE TABLE asterisk.trunk_dialpatterns;"
        mysql -uroot -p$MYSQLPWD $TEMPDB -e "INSERT INTO asterisk.trunk_dialpatterns SELECT trunkid, match_pattern_prefix, match_pattern_pass, prepend_digits, seq FROM trunk_dialpatterns;"
	echo trunks
	mysql -uroot -p$MYSQLPWD $TEMPDB -e "TRUNCATE TABLE asterisk.trunks;"
        mysql -uroot -p$MYSQLPWD $TEMPDB -e "INSERT INTO asterisk.trunks SELECT trunkid, name, tech, outcid, keepcid, maxchans, failscript, dialoutprefix, channelid, usercontext, provider, disabled, 'continue' FROM trunks;"
	echo users
	mysql -uroot -p$MYSQLPWD $TEMPDB -e "TRUNCATE TABLE asterisk.users;"
        mysql -uroot -p$MYSQLPWD $TEMPDB -e "INSERT INTO asterisk.users SELECT extension, password, name, voicemail, ringtimer, noanswer, recording, outboundcid, sipname, mohclass, noanswer_cid, busy_cid, chanunavail_cid, noanswer_dest, busy_dest, chanunavail_dest FROM users;"
	echo vmblast
	mysql -uroot -p$MYSQLPWD $TEMPDB -e "TRUNCATE TABLE asterisk.vmblast;"
        mysql -uroot -p$MYSQLPWD $TEMPDB -e "INSERT INTO asterisk.vmblast SELECT grpnum, description, audio_label, password FROM vmblast;"
	echo vmblast_groups
	mysql -uroot -p$MYSQLPWD $TEMPDB -e "TRUNCATE TABLE asterisk.vmblast_groups;"
        mysql -uroot -p$MYSQLPWD $TEMPDB -e "INSERT INTO asterisk.vmblast_groups SELECT grpnum, ext FROM vmblast_groups;"
	echo voicemail_admin
	mysql -uroot -p$MYSQLPWD $TEMPDB -e "TRUNCATE TABLE asterisk.voicemail_admin;"
        mysql -uroot -p$MYSQLPWD $TEMPDB -e "INSERT INTO asterisk.voicemail_admin SELECT variable, value FROM voicemail_admin;"
	echo Custom Contexts
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
	echo FAIL
fi
check_versions
echo -e "Backing up actual configuaration to $DATADIR... \c"
keep_files
cp -p /var/www/html/index.php $DATADIR
echo OK
echo "Creating temp DB $TEMPDB(this may take a long time...)"
restore_asterisktempsql
echo "Done"
echo -e "Restoring Asterisk DB... \c"
#if restore_asterisksql
if restore_sqlfromtemp
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
/usr/sbin/amportal a r
