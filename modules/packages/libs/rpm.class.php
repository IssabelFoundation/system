<?php
/* vim: set expandtab tabstop=4 softtabstop=4 shiftwidth=4:
  Codificación: UTF-8
  +----------------------------------------------------------------------+
  | Elastix version 2.0.4                                                |
  | http://www.elastix.com                                               |
  +----------------------------------------------------------------------+
  | Copyright (c) 2006 Palosanto Solutions S. A.                         |
  +----------------------------------------------------------------------+
  | Cdla. Nueva Kennedy Calle E 222 y 9na. Este                          |
  | Telfs. 2283-268, 2294-440, 2284-356                                  |
  | Guayaquil - Ecuador                                                  |
  | http://www.palosanto.com                                             |
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
  | The Original Code is: Elastix Open Source.                           |
  | The Initial Developer of the Original Code is PaloSanto Solutions    |
  +----------------------------------------------------------------------+
  $Id: rpm.class.php,v 1.0 2013-12-10 12:40:05 Luis Abarca Villacís.  labarca@palosanto.com Exp $*/

class core_QueryRpms
{
    private $errMsg = NULL;
    private static $_RPM_QUERY_FORMAT = "%{NAME}|%{VERSION}|%{RELEASE}\n";

    function listall($length)
    {
        if ($length != 'correct') {
            $this->errMsg["fc"] = 'BADLENGTH';
            $this->errMsg["fm"] = 'Length of this url is not correct';
            $this->errMsg["fd"] = 'This URL not accept more options';
            return TRUE;
        }

        list($inst, $notinst) = $this->_listRpmGroups();
        return array_merge($inst, $notinst);
    }

    function notinstalled()
    {
        list($inst, $notinst) = $this->_listRpmGroups();
        return $notinst;
    }

    function installed()
    {
        list($inst, $notinst) = $this->_listRpmGroups();
        return $inst;
    }

    function onlyone($rpm)
    {
        list($rpms, $retval) = $this->_rpmquery(array($rpm));
        if ($retval == 0 && count($rpms) > 0) {
            return $rpms[0];
        } else {
            return array(
                'Name'      =>  $rpm,
                'Status'    =>  'Not Installed',
            );
        }
    }

     /**
     *
     * Function that returns the error message
     *
     * @return  string   Message error if had an error.
     */
    public function getError()
    {
        return $this->errMsg;
    }

    private function _listRpmGroups()
    {
        $rpmset = $this->_rpmSet();
        list($rpms, $retval) = $this->_rpmquery($rpmset);
        $installed = array();
        $notinstalled = array();
        foreach ($rpms as $rpm) if (in_array($rpm['Name'], $rpmset)) {
            $installed[] = $rpm;
            $rpmset = array_diff($rpmset, array($rpm['Name']));
        }
        foreach ($rpmset as $missing) {
            $notinstalled[] = array('Name' => $missing, 'Status' => 'Not Installed');
        }
        return array($installed, $notinstalled);

    }

    private function _rpmquery($packagelist)
    {
        $cmd = '/usr/bin/rpm -q --queryformat '.
            escapeshellarg(self::$_RPM_QUERY_FORMAT).' '.
            implode(' ', array_map('escapeshellarg', $packagelist));
        $output = $retval = NULL;
        exec($cmd, $output, $retval);
        $l = array();
        foreach ($output as $s) {
            $t = explode('|', $s);
            if (count($t) == 3) $l[] = array_combine(
                array('Name', 'Version', 'Release'),
                $t);
        }
        return array($l, $retval);
    }

    private function _rpmSet()
    {
        return array_map('trim', file("/var/www/db/rpms_availables"));
    }
}