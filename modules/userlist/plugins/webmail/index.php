<?php
/* vim: set expandtab tabstop=4 softtabstop=4 shiftwidth=4:
 Codificación: UTF-8
 +----------------------------------------------------------------------+
 | Elastix version 0.5                                                  |
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
 $Id: paloSantoACL.class.php,v 1.1.1.1 2007/07/06 21:31:55 gcarrillo Exp $ */

class paloUserPlugin_webmail extends paloSantoUserPluginBase
{
    function addFormElements($privileged)
    {
        return array(
            "webmailpassword1"   => array(
                "LABEL"                  => _tr("Webmail Password"),
                "REQUIRED"               => "no",
                "INPUT_TYPE"             => "PASSWORD",
                "INPUT_EXTRA_PARAM"      => "",
                "VALIDATION_TYPE"        => "text",
                "VALIDATION_EXTRA_PARAM" => ""
            ),
            "webmailuser"       => array(
                "LABEL"                  => _tr("Webmail User"),
                "REQUIRED"               => "no",
                "INPUT_TYPE"             => "TEXT",
                "INPUT_EXTRA_PARAM"      => "",
                "VALIDATION_TYPE"        => "text",
                "VALIDATION_EXTRA_PARAM" => ""
            ),
            "webmaildomain"       => array(
                "LABEL"                  => _tr("Webmail Domain"),
                "REQUIRED"               => "no",
                "INPUT_TYPE"             => "TEXT",
                "INPUT_EXTRA_PARAM"      => "",
                "VALIDATION_TYPE"        => "text",
                "VALIDATION_EXTRA_PARAM" => ""
            ),
        );
    }

    function loadFormEditValues($username, $id_user)
    {
        $listaPropiedades = $this->_pACL->getUserProfile($id_user, 'webmail');
        if (!is_array($listaPropiedades)) {
            print "ERROR DE DB: ".$pACL->errMsg;
            $listaPropiedades = array();
        }
        if (!isset($_POST['webmaildomain']) && isset($listaPropiedades['domain']))
            $_POST['webmaildomain'] = $listaPropiedades['domain'];
        if (!isset($_POST['webmailuser']) && isset($listaPropiedades['login']))
            $_POST['webmailuser'] = $listaPropiedades['login'];
        if (!isset($_POST['webmailpassword1']) && isset($listaPropiedades['password']))
            $_POST['webmailpassword1'] = '********';
    }

    function fetchForm($smarty, $oForm, $local_templates_dir, $pvars)
    {
        $smarty->assign('LBL_WEBMAIL_FIELDS', _tr("Mail Profile"));
        return $oForm->fetchForm("$local_templates_dir/new_webmail.tpl", '', $pvars);
    }

    function runPostCreateUser($smarty, $username, $id_user)
    {
        $listaPropiedades = array();
        foreach (array(
            'webmailuser' => 'login', 'webmailpassword1' => 'password', 'webmaildomain' => 'domain')
            as $k => $v) {
            $listaPropiedades[$v] = (!empty($_POST[$k])) ? $_POST[$k] : NULL;
        }
        if ($listaPropiedades['password'] == '********') unset($listaPropiedades['password']);
        $r = $this->_pACL->saveUserProfile($id_user, 'webmail', $listaPropiedades);
        if (!$r) {
            $smarty->assign(array(
                'mb_title'  =>  'ERROR',
                'mb_message'=>  $this->_pACL->errMsg,
            ));
            return FALSE;
        }
        return TRUE;
    }

    function runPostUpdateUser($smarty, $username, $id_user, $privileged)
    {
        return $this->runPostCreateUser($smarty, $username, $id_user);
    }
}
