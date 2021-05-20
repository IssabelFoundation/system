<?php
  /* vim: set expandtab tabstop=4 softtabstop=4 shiftwidth=4:
  Codificación: UTF-8
  +----------------------------------------------------------------------+
  | Issabel version 1.5-9                                                |
  | http://www.issabel.org                                               |
  +----------------------------------------------------------------------+
  | Copyright (c) 2021 Issabel Foundation                                |
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
  $Id: paloSantoDhcpClient.class.php, Thu 20 May 2021 09:04:46 AM EDT, nicolas@issabel.com
*/
class paloSantoDhcpClienList {
    var $_DB;
    var $errMsg;

    function __construct(&$pDB)
    {
        // Se recibe como parámetro una referencia a una conexión paloDB
        if (is_object($pDB)) {
            $this->_DB =& $pDB;
            $this->errMsg = $this->_DB->errMsg;
        } else {
            $dsn = (string)$pDB;
            $this->_DB = new paloDB($dsn);

            if (!$this->_DB->connStatus) {
                $this->errMsg = $this->_DB->errMsg;
                // debo llenar alguna variable de error
            } else {
                // debo llenar alguna variable de error
            }
        }
    }


    /////////NEW FUNCTIONS FOR MODULE DHCP_CLIENT
    
    function getDhcpClientList()
    {
	    $data = array();
	    $i = 0;    // Por compat, la lista empieza desde 1
        foreach (file('/var/lib/dhcpd/dhcpd.leases') as $line) {
            // Saltarse los comentarios
            if (preg_match('/^\s*#/', $line)) continue;
            
            $regs = NULL;
            if (preg_match('/^\s*lease\s+([0-9.]+)/i', $line, $regs)) {
                $data[++$i] = array('iphost'    =>  $regs[1]);
            } elseif (preg_match('|^\s*starts\s+\d+\s+([0-9/]+)\s+([0-9:]+)|i', $line, $regs)) {
                $data[$i]['date_starts'] = $regs[1].' '.$regs[2];
            } elseif (preg_match('|^\s*ends\s+\d+\s+([0-9/]+)\s+([0-9:]+)|i', $line, $regs)) {
                $data[$i]['date_ends'] = $regs[1].' '.$regs[2];
            } elseif (preg_match('/hardware\s+\S+\s+([a-z0-9:]+)/i', $line, $regs)) {
                $data[$i]['macaddress'] = $regs[1];
            } elseif (preg_match('/^\s*binding\sstate\s+(\w+)/i', $line, $regs)) {
                $data[$i]['binding state'] = $regs[1];
            }
        }

        return $data;
    }
    
    function getDhcpClientListById($id)
    {
        $result = array();
        $arrResult = $this->getDhcpClientList();

        if ($id >= 1 && $id <= count($arrResult)) {
            $result = $arrResult[$id];
            if ($result['date_ends'] == '') $result['date_ends'] = 'never';
        }

        return $result;
    }
}
?>
