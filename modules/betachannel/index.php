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
  $Id: index.php,v 1.0 2023-09-09 Nicolás Gudiño nicolas@issabel.com Exp $
*/
//include issabel framework
include_once "libs/paloSantoGrid.class.php";
include_once "libs/paloSantoForm.class.php";
include_once "libs/paloSantoJSON.class.php";
require_once("libs/misc.lib.php");

function _moduleContent(&$smarty, $module_name)
{
    //include module files
    include_once "modules/$module_name/configs/default.conf.php";

    load_language_module($module_name);

    //global variables
    global $arrConf;
    global $arrConfModule;
    $arrConf = array_merge($arrConf,$arrConfModule);

    //folder path for custom templates
    $base_dir=dirname($_SERVER['SCRIPT_FILENAME']);
    $templates_dir=(isset($arrConf['templates_dir']))?$arrConf['templates_dir']:'themes';
    $local_templates_dir="$base_dir/modules/$module_name/".$templates_dir.'/'.$arrConf['theme'];

    //actions
    $action = getAction();
    $content = "";
    switch($action){
        case "update_beta_channel_status":
            $content = updateBetaChannelStatus($arrConf);
            break;
        default: // view_form
            $content = viewFormBetaChannel($smarty, $module_name, $local_templates_dir, $arrConf);
            break;
    }
    return $content;
}

function viewFormBetaChannel($smarty, $module_name, $local_templates_dir, $arrConf)
{
    $pBetaChannel       = new IssabelBetaChannel($arrConf);
    $value_beta_channel = $pBetaChannel->isEnabledBetaChannel();
    $arrFormBetaChannel = createFieldForm();
    $oForm = new paloForm($smarty,$arrFormBetaChannel);

    $smarty->assign("subtittle1", _tr("Enable beta channel"));
    $smarty->assign("value_beta_channel", ($value_beta_channel=='enabled')?1:0);

    $htmlForm = $oForm->fetchForm("$local_templates_dir/form.tpl",_tr("Beta Channel"), $_POST);
    $content = $htmlForm;
    return $content;
}

function updateBetaChannelStatus($arrConf) {

    $pBetaChannel            = new IssabelBetaChannel($arrConf);
    $jsonObject              = new PaloSantoJSON();
    $statusBetaChannel       = getParameter("new_beta_channel_status");
    $result                  = $pBetaChannel->updateBetaChannelStatus($statusBetaChannel);
    $arrData['result']       = $result;
    $arrData['button_title'] = _tr("Dismiss");
    if($statusBetaChannel == "1") {
       $word = _tr("enabled");
    } else {
       $word = _tr("disabled");
    }
    if($result) {
        $arrData['message_title'] = _tr("Information").":<br/>";
        $arrData['message']       = sprintf(_tr("Issabel Beta repository is now %s"),$word);
    } else {
        $arrData['message_title'] = _tr("Error").":<br/>";
        $arrData['message']       = sprintf(_tr("Problem setting Issabel Beta repository to %s state."),$word);
    }
    $jsonObject->set_message($arrData);
    Header('Content-Type: application/json');
    return $jsonObject->createJSON();
}

function createFieldForm() {
    $arrFields = array(
        "beta_channel_status" => array( 
            "LABEL"                  => _tr('Enable beta channel'),
            "REQUIRED"               => "no",
            "INPUT_TYPE"             => "CHECKBOX",
            "INPUT_EXTRA_PARAM"      => "",
            "VALIDATION_TYPE"        => "text",
            "VALIDATION_EXTRA_PARAM" => "",
        )
    );
    return $arrFields;
}

function getAction() {
    $action = getParameter("action");
    if($action=='update_beta_channel_status')  {
        return "update_beta_channel_status";
    } else {
        return "view_form";
    }
}
?>
