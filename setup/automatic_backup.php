#!/usr/bin/php
<?php
/*
  vim: set expandtab tabstop=4 softtabstop=4 shiftwidth=4:
  Codificación: UTF-8
  +----------------------------------------------------------------------+
  | Issabel version 4.0                                                  |
  | http://www.issabel.org                                               |
  +----------------------------------------------------------------------+
  | Copyright (c) 2006 Palosanto Solutions S. A.                         |
  +----------------------------------------------------------------------+
  | The contents of this file are subject to the General Public License  |
  | (GPL) Version 2 (the "License"); you may not use this file except in |
  | compliance with the License. You may obtain a copy of the License at |
  | http://www.opensource.org/licenses/gpl-license.php                   |
  |                                                                      |
  | Software distributed under the License is distributed on an "AS IS"  |
  | basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See  |
  | the License for the specific language governing rights and           |
  | limitations under the License.                                       |
  +----------------------------------------------------------------------+
  | The Initial Developer of the Original Code is PaloSanto Solutions    |
  +----------------------------------------------------------------------+
  $Id: dhcpconfig.php,v 1.1 2007/01/09 23:49:36 alex Exp $
*/
load_default_timezone();

// All of the following assumes this script runs as root
$sBackupFilename = 'issabelbackup-'.date('YmdHis').'-ab.tar';
$sBackupDir = '/var/www/backup';
$BackupComponents = 'as_db,as_config_files,as_sounds,as_mohmp3,as_dahdi,email,fax,endpoint,otros,otros_new';
$retval = NULL;
system('/usr/share/issabel/privileged/backupengine --backup --backupfile '.
    $sBackupFilename.' --tmpdir '.$sBackupDir.' --components='.$BackupComponents, $retval);
exit($retval);

function load_default_timezone()
{
    $sDefaultTimezone = @date_default_timezone_get();
    if ($sDefaultTimezone == 'UTC') {
        $sDefaultTimezone = 'America/New_York';
        $regs = NULL;
        if (is_link("/etc/localtime") && preg_match("|/usr/share/zoneinfo/(.+)|", readlink("/etc/localtime"), $regs)) {
            $sDefaultTimezone = $regs[1];
        } elseif (file_exists('/etc/sysconfig/clock')) {
            foreach (file('/etc/sysconfig/clock') as $s) {
                $regs = NULL;
                if (preg_match('/^ZONE\s*=\s*"(.+)"/', $s, $regs)) {
                    $sDefaultTimezone = $regs[1];
                }
            }
        }
    }
    date_default_timezone_set($sDefaultTimezone);
}
?>
