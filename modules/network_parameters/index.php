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
  $Id: index.php,v 1.1.1.1 2007/07/06 21:31:56 gcarrillo Exp $ */

function _moduleContent(&$smarty, $module_name)
{
    include_once "libs/paloSantoForm.class.php";
    include_once "libs/paloSantoNetwork.class.php";
    include_once "libs/paloSantoGrid.class.php";
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

    $arrFormNetwork  = array("host"         => array("LABEL"                  => ""._tr('Host')." (Ex. host.example.com)",
                                                     "REQUIRED"               => "yes",
                                                     "INPUT_TYPE"             => "TEXT",
                                                     "INPUT_EXTRA_PARAM"      => "",
                                                     "VALIDATION_TYPE"        => "domain",
                                                     "VALIDATION_EXTRA_PARAM" => ""),
                             "dns1"         => array("LABEL"                  => _tr("Primary DNS"),
                                                     "REQUIRED"               => "yes",
                                                     "INPUT_TYPE"             => "TEXT",
                                                     "INPUT_EXTRA_PARAM"      => "",
                                                     "VALIDATION_TYPE"        => "ip",
                                                     "VALIDATION_EXTRA_PARAM" => ""),
                             "dns2"         => array("LABEL"                  => _tr("Secondary DNS"),
                                                     "REQUIRED"               => "no",
                                                     "INPUT_TYPE"             => "TEXT",
                                                     "INPUT_EXTRA_PARAM"      => "",
                                                     "VALIDATION_TYPE"        => "ip",
                                                     "VALIDATION_EXTRA_PARAM" => ""),
                             "gateway"      => array("LABEL"                  => _tr("Default Gateway"),
                                                     "REQUIRED"               => "yes",
                                                     "INPUT_TYPE"             => "TEXT",
                                                     "INPUT_EXTRA_PARAM"      => "",
                                                     "VALIDATION_TYPE"        => "ip",
                                                     "VALIDATION_EXTRA_PARAM" => ""));

    $arrFormInterfase = array("ip"          => array("LABEL"                  => _tr("IP Address"),
                                                     "REQUIRED"               => "yes",
                                                     "INPUT_TYPE"             => "TEXT",
                                                     "INPUT_EXTRA_PARAM"      => "",
                                                     "VALIDATION_TYPE"        => "ip",
                                                     "VALIDATION_EXTRA_PARAM" => ""),
                             "mask"         => array("LABEL"                  => _tr("Network Mask"),
                                                     "REQUIRED"               => "yes",
                                                     "INPUT_TYPE"             => "TEXT",
                                                     "INPUT_EXTRA_PARAM"      => "",
                                                     "VALIDATION_TYPE"        => "mask",
                                                     "VALIDATION_EXTRA_PARAM" => ""),
                             "type"         => array("LABEL"                  => _tr("Interface Type"),
                                                     "REQUIRED"               => "yes",
                                                     "INPUT_TYPE"             => "RADIO",
                                                     "INPUT_EXTRA_PARAM"      => array("static" => "Static", "dhcp" => "DHCP"),
                                                     "VALIDATION_TYPE"        => "text",
                                                     "VALIDATION_EXTRA_PARAM" => ""),
                             "dev_id"       => array("LABEL"                  => _tr("Device"),
                                                     "REQUIRED"               => "yes",
                                                     "INPUT_TYPE"             => "HIDDEN",
                                                     "INPUT_EXTRA_PARAM"      => "",
                                                     "VALIDATION_TYPE"        => "ereg",
                                                     "VALIDATION_EXTRA_PARAM" => "^[[:alnum:]-]+$"));

    $strReturn ="";

    $pNet = new paloNetwork();

    // MANEJO DE ACCIONES

    if(isset($_POST['edit'])) {

        $arrNetwork = $pNet->obtener_configuracion_red();

        if(is_array($arrNetwork)) {
            $arrNetworkData['dns1'] = isset($arrNetwork['dns'][0])?$arrNetwork['dns'][0]:'';
            $arrNetworkData['dns2'] = isset($arrNetwork['dns'][1])?$arrNetwork['dns'][1]:'';
            $arrNetworkData['host'] = isset($arrNetwork['host'])?$arrNetwork['host']:'';
            $arrNetworkData['gateway'] = isset($arrNetwork['gateway'])?$arrNetwork['gateway']:'';
        }

        $oForm = new paloForm($smarty, $arrFormNetwork);
        $smarty->assign("ETHERNET_INTERFASES_LIST", "");
        $smarty->assign("CANCEL", _tr("Cancel"));
        $smarty->assign("SAVE", _tr("Save"));
        $smarty->assign("REQUIRED_FIELD", _tr("Required field"));
	$smarty->assign("icon","modules/network_parameters/images/system_network_network_parameters.png");
        $strReturn = $oForm->fetchForm("$local_templates_dir/network.tpl", _tr("Network Parameters"), $arrNetworkData);

    } else if(isset($_POST['save_network_changes'])) {

        $oForm = new paloForm($smarty, $arrFormNetwork);

        if($oForm->validateForm($_POST)) {
            $arrNetConf['host'] = $_POST['host'];
            $arrNetConf['dns_ip_1'] = $_POST['dns1'];
            $arrNetConf['dns_ip_2'] = $_POST['dns2'];
            $arrNetConf['gateway_ip'] = $_POST['gateway'];
            $pNet->escribir_configuracion_red_sistema($arrNetConf);
            if(!empty($pNet->errMsg)) {
                $smarty->assign("mb_message", $pNet->errMsg);
            } else {
                header("Location: index.php?menu=network");
            }
        } else {
            // Error
            $smarty->assign("mb_title", _tr("Validation Error"));
            $arrErrores=$oForm->arrErroresValidacion;
            $strErrorMsg = "<b>"._tr('The following fields contain errors').":</b><br>";
            foreach($arrErrores as $k=>$v) {
                $strErrorMsg .= "$k, ";
            }
            $strErrorMsg .= "";
            $smarty->assign("mb_message", $strErrorMsg);
            $smarty->assign("CANCEL", _tr("Cancel"));
            $smarty->assign("SAVE", _tr("Save"));
            $smarty->assign("REQUIRED_FIELD", _tr("Required field"));
            $strReturn=$oForm->fetchForm("$local_templates_dir/network.tpl", _tr("Network Parameters"), $_POST);
        }
	$smarty->assign("icon","modules/network_parameters/images/system_network_network_parameters.png");
        // Se aplasto el boton de grabar los cambios en la red

    } else if(isset($_POST['cancel_interfase_edit'])) {

        header("Location: index.php?menu=network");

    } else if(isset($_POST['save_interfase_changes'])) {

        $oForm = new paloForm($smarty, $arrFormInterfase);

        if($oForm->validateForm($_POST)) {
	    $smarty->assign("icon","modules/network_parameters/images/system_network_network_parameters.png");
            if($pNet->escribirConfiguracionInterfaseRed($_POST['dev_id'], $_POST['type'], $_POST['ip'], $_POST['mask'])) {
                header("Location: index.php?menu=network");
            } else {
                $smarty->assign("mb_title", _tr("ERROR"));
                $smarty->assign("mb_message", $pNet->errMsg);
            }
        } else {
            // Error
            $smarty->assign("mb_title", _tr("Validation Error"));
            $arrErrores=$oForm->arrErroresValidacion;
            $strErrorMsg = "<b>"._tr('The following fields contain errors').":</b><br>";
            foreach($arrErrores as $k=>$v) {
                $strErrorMsg .= "$k, ";
            }
            $strErrorMsg .= "";
            $smarty->assign("mb_message", $strErrorMsg);
            $smarty->assign("CANCEL", _tr("Cancel"));
            $smarty->assign("APPLY_CHANGES", _tr("Apply changes"));
            $smarty->assign("REQUIRED_FIELD", _tr("Required field"));
            $smarty->assign("EDIT_PARAMETERS", _tr("Edit Network Parameters"));
	    $smarty->assign("icon","/modules/$module_name/images/system_hardware_detector.png");
            $smarty->assign("CONFIRM_EDIT", _tr("Are you sure you want to edit network parameters?"));
            $strReturn=$oForm->fetchForm("$local_templates_dir/network_edit_interfase.tpl", ""._tr('Edit Interface')." \"Ethernet ??\"", $_POST);
        }
    } else if(isset($_GET['action']) && $_GET['action'] == "editInterfase") {

        // TODO: Revisar si el $_GET['id'] contiene un id valido
        $arrEths = $pNet->obtener_interfases_red_fisicas();
        $arrEth = $arrEths[$_GET['id']];

        if(is_array($arrEth)) {
            $arrInterfaseData['ip'] = $arrEth['Inet Addr'];
            $arrInterfaseData['mask'] = $arrEth['Mask'];
            $arrInterfaseData['type'] = $arrEth['Type'];
            $arrInterfaseData['dev_id'] = $_GET['id'];
        }

        $oForm = new paloForm($smarty, $arrFormInterfase);
        $smarty->assign("CANCEL", _tr("Cancel"));
        $smarty->assign("APPLY_CHANGES", _tr("Apply changes"));
        $smarty->assign("REQUIRED_FIELD", _tr("Required field"));
        $smarty->assign("EDIT_PARAMETERS", _tr("Edit Network Parameters"));
	$smarty->assign("icon","/modules/$module_name/images/system_hardware_detector.png");
        $smarty->assign("CONFIRM_EDIT", _tr("Are you sure you want to edit network parameters?"));
        $strReturn = $oForm->fetchForm("$local_templates_dir/network_edit_interfase.tpl", ""._tr('Edit Interface')." \"" . $arrEth['Name'] . "\"", $arrInterfaseData);
    } else {
        // SECCION NETWORK PARAMETERS
        $arrNetwork = $pNet->obtener_configuracion_red();

        if(is_array($arrNetwork)) {
            $arrNetworkData['dns1'] = isset($arrNetwork['dns'][0])?$arrNetwork['dns'][0]:'';
            $arrNetworkData['dns2'] = isset($arrNetwork['dns'][1])?$arrNetwork['dns'][1]:'';
            $arrNetworkData['host'] = isset($arrNetwork['host'])?$arrNetwork['host']:'';
            $arrNetworkData['gateway'] = isset($arrNetwork['gateway'])?$arrNetwork['gateway']:'';
        }

        $oForm = new paloForm($smarty, $arrFormNetwork);
        $oForm->setViewMode();

        // SECCION ETHERNET LIST
        $arrData = array();
        $arrEths = $pNet->obtener_interfases_red_fisicas();
        $end = count($arrEths);

        foreach($arrEths as $idEth=>$arrEth) {
            $arrTmp    = array();
            $arrTmp[0] = "&nbsp;<a href='?menu=network&action=editInterfase&id=$idEth'>" . $arrEth['Name'] . "</a>";
            $arrTmp[1] = strtoupper($arrEth['Type']);
            $arrTmp[2] = $arrEth['Inet Addr'];
            $arrTmp[3] = $arrEth['Mask'];
            $arrTmp[4] = $arrEth['HWaddr'];
            $arrTmp[5] = isset($arrEth['HW_info'])?$arrEth['HW_info']:''; //- Deberia acotar este campo pues puede ser muy largo
            $arrTmp[6] = ($arrEth['Running']=="Yes" ? "<font color=green>"._tr("Connected")."</font>" : "<font color=red>"._tr("Not Connected")."</font>");
            $arrData[] = $arrTmp;
        }

        $oGrid = new paloSantoGrid($smarty);
        $oGrid->pagingShow(false);

        $arrGrid = array("title"    => _tr("Ethernet Interfaces List"),
                         "icon"     => "/modules/$module_name/images/system_hardware_detector.png",
                         "width"    => "99%",
                         "start"    => "1",
                         "end"      => $end,
                         "total"    => $end,
                         "columns"  => array(0 => array("name"      => _tr("Device"),
                                                        "property1" => ""),
                                             1 => array("name"      => _tr("Type"),
                                                        "property1" => ""),
                                             2 => array("name"      => _tr("IP"),
                                                        "property1" => ""),
                                             3 => array("name"      => _tr("Mask"),
                                                        "property1" => ""),
                                             4 => array("name"      => _tr("MAC Address"),
                                                        "property1" => ""),
                                             5 => array("name"      => _tr("HW Info"),
                                                        "property1" => ""),
                                             6 => array("name"      => _tr("Status"),
                                                        "property1" => "")
                                            ));

        $htmlGrid = $oGrid->fetchGrid($arrGrid, $arrData);
        $smarty->assign("ETHERNET_INTERFASES_LIST", $htmlGrid);
        $smarty->assign("EDIT_PARAMETERS", _tr("Edit Network Parameters"));
        $smarty->assign("REQUIRED_FIELD", _tr("Required field"));
	$smarty->assign("icon","modules/network_parameters/images/system_network_network_parameters.png");
        // DISPLAY
        $strReturn = $oForm->fetchForm("$local_templates_dir/network.tpl", _tr("Network Parameters"), $arrNetworkData);
    }

    return $strReturn;
}
?>
