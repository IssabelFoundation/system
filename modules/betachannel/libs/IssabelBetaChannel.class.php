<?php
  /* vim: set expandtab tabstop=4 softtabstop=4 shiftwidth=4:
  Codificación: UTF-8
  +----------------------------------------------------------------------+
  | Issabel version 5.0                                                  |
  | http://www.issabel.org                                               |
  +----------------------------------------------------------------------+
  | Copyright (c) 2023 Issabel Foundation                                |
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
  $Id: IssabelBetaChannel.class.php,v 1.0 2023-09-09 11:05:31 Nicolás Gudiño nicolas@issabel.com Exp $
*/
 
class IssabelBetaChannel {
    var $_DB;
    var $errMsg;
    var $arrConf;

    function __construct($arrConf) {
        $this->arrConf = $arrConf;
    }

    function updateBetaChannelStatus($status_beta_channel) {
        //Actualizar el estado del repositorio beta
        $output = $retval = NULL;
        if($status_beta_channel==1) {
            exec('/usr/bin/issabel-helper betachannel --enable', $output, $retval);
        } else {
            exec('/usr/bin/issabel-helper betachannel --disable', $output, $retval);
        }
        return $retval;
    }

    function isEnabledBetaChannel() {
        $output = $retval = NULL;
        exec('/usr/bin/issabel-helper betachannel --status', $output, $retval);
        return $output[0];
    }

}
?>
