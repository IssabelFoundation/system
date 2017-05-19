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
    include_once("libs/paloSantoDB.class.php");
    include_once("libs/paloSantoConfig.class.php");
    include_once("libs/paloSantoGrid.class.php");
    include_once("libs/paloSantoACL.class.php");
    include_once "modules/$module_name/configs/default.conf.php";

    load_language_module($module_name);

    //global variables
    global $arrConf;
    global $arrConfModule;
    $arrConf = array_merge($arrConf,$arrConfModule);

    //conexion acl.db
    $pDB = new paloDB($arrConf['elastix_dsn']['acl']);

    //folder path for custom templates
    $base_dir=dirname($_SERVER['SCRIPT_FILENAME']);
    $templates_dir=(isset($arrConf['templates_dir']))?$arrConf['templates_dir']:'themes';
    $local_templates_dir="$base_dir/modules/$module_name/".$templates_dir.'/'.$arrConf['theme'];

    $pConfig = new paloConfig("/etc", "amportal.conf", "=", "[[:space:]]*=[[:space:]]*");
    $arrConfig = $pConfig->leer_configuracion(false);

    $dsn = $arrConfig['AMPDBENGINE']['valor'] . "://" . $arrConfig['AMPDBUSER']['valor'] . ":" . $arrConfig['AMPDBPASS']['valor'] . "@" . $arrConfig['AMPDBHOST']['valor'] . "/asterisk";
    $pDBa     = new paloDB($dsn);

////////////////////

    if(!empty($pDB->errMsg)) {
        echo "ERROR DE DB: $pDB->errMsg <br>";
    }

    $arrData = array();
    $arrData[""] = _tr("no extension");
    $pACL = new paloACL($pDB);
    if(!empty($pACL->errMsg)) {
        echo "ERROR DE ACL: $pACL->errMsg <br>";
    }

/*******/
    $typeUser = "";
    $userLevel1 = "";
    $extOther = "";
    $userAccount = isset($_SESSION['elastix_user'])?$_SESSION['elastix_user']:"";
    $idUserAccount = $pACL->isUserAdministratorGroup($userAccount);
    $idUserInt = $pACL->getIdUser($userAccount);
    if($idUserAccount)
        $userLevel1 = "admin";
    else
        $userLevel1 = "other";
    $smarty->assign("userLevel1", $userLevel1);
/*******/
    $sQuery="select extension from users order by extension;";
    $arrayResult = $pDBa->fetchTable($sQuery,true);
    if (!$arrayResult){
        $error = $pDBa->errMsg;
    }else{
        if (is_array($arrayResult) && count($arrayResult)>0) {
            //$arrData[$item["null"]] = "No extension";
            if($idUserAccount){
                foreach($arrayResult as $item) {
                    $arrData[$item["extension"]] = $item["extension"];
                }
            }else{
                $idOther = $pACL->getIdUser($userAccount);
                $arrUserOther = $pACL->getUsers($idOther);
                $extOther = $arrUserOther[0][3];
                $arrData[$extOther] = $extOther;
            }
        }
    }

    $arrGruposACL=$pACL->getGroups();
    for($i=0; $i<count($arrGruposACL); $i++)
    {
        if($arrGruposACL[$i][1]=='administrator')
            $arrGruposACL[$i][1] = _tr('administrator');
        else if($arrGruposACL[$i][1]=='operator')
            $arrGruposACL[$i][1] = _tr('operator');
        else if($arrGruposACL[$i][1]=='extension')
            $arrGruposACL[$i][1] = _tr('extension');
        if($idUserAccount)
            $arrGrupos[$arrGruposACL[$i][0]] = $arrGruposACL[$i][1];
        else{
            $arrUserPer = $pACL->getMembership($idUserInt);
            foreach($arrUserPer as $key => $value){
                if($arrGruposACL[$i][1] == $key){
                    $arrGrupos[$arrGruposACL[$i][0]] = $arrGruposACL[$i][1];
                }
            }
        }
    }

    $arrFormElements = array("description" => array("LABEL"                  => ""._tr('Name')." "._tr('(Ex. John Doe)')."",
                                                    "REQUIRED"               => "no",
                                                    "INPUT_TYPE"             => "TEXT",
                                                    "INPUT_EXTRA_PARAM"      => "",
                                                    "VALIDATION_TYPE"        => "text",
                                                    "VALIDATION_EXTRA_PARAM" => ""),
                             "name"       => array("LABEL"                   => _tr("Login"),
                                                    "REQUIRED"               => "yes",
                                                    "INPUT_TYPE"             => "TEXT",
                                                    "INPUT_EXTRA_PARAM"      => "",
                                                    "VALIDATION_TYPE"        => "text",
                                                    "VALIDATION_EXTRA_PARAM" => "",
                                                    "EDITABLE"               => "no"),
                             "password1"   => array("LABEL"                  => _tr("Password"),
                                                    "REQUIRED"               => "yes",
                                                    "INPUT_TYPE"             => "PASSWORD",
                                                    "INPUT_EXTRA_PARAM"      => "",
                                                    "VALIDATION_TYPE"        => "text",
                                                    "VALIDATION_EXTRA_PARAM" => ""),
                             "password2"   => array("LABEL"                  => _tr("Retype password"),
                                                    "REQUIRED"               => "yes",
                                                    "INPUT_TYPE"             => "PASSWORD",
                                                    "INPUT_EXTRA_PARAM"      => "",
                                                    "VALIDATION_TYPE"        => "text",
                                                    "VALIDATION_EXTRA_PARAM" => ""),
                             "group"       => array("LABEL"                  => _tr("Group"),
                                                    "REQUIRED"               => "no",
                                                    "INPUT_TYPE"             => "SELECT",
                                                    "INPUT_EXTRA_PARAM"      => $arrGrupos,
                                                    "VALIDATION_TYPE"        => "text",
                                                    "VALIDATION_EXTRA_PARAM" => ""),
                            "extension"   => array("LABEL"                  => _tr("Extension"),
                                                    "REQUIRED"               => "no",
                                                    "INPUT_TYPE"             => "SELECT",
                                                    "INPUT_EXTRA_PARAM"      => $arrData,
                                                    "VALIDATION_TYPE"        => "text",
                                                    "VALIDATION_EXTRA_PARAM" => ""),
                             "webmailpassword1"   => array("LABEL"                  => _tr("Webmail Password"),
                                                    "REQUIRED"               => "no",
                                                    "INPUT_TYPE"             => "PASSWORD",
                                                    "INPUT_EXTRA_PARAM"      => "",
                                                    "VALIDATION_TYPE"        => "text",
                                                    "VALIDATION_EXTRA_PARAM" => ""),
                             "webmailuser"       => array("LABEL"                  => _tr("Webmail User"),
                                                    "REQUIRED"               => "no",
                                                    "INPUT_TYPE"             => "TEXT",
                                                    "INPUT_EXTRA_PARAM"      => "",
                                                    "VALIDATION_TYPE"        => "text",
                                                    "VALIDATION_EXTRA_PARAM" => ""),
                             "webmaildomain"       => array("LABEL"                  => _tr("Webmail Domain"),
                                                    "REQUIRED"               => "no",
                                                    "INPUT_TYPE"             => "TEXT",
                                                    "INPUT_EXTRA_PARAM"      => "",
                                                    "VALIDATION_TYPE"        => "text",
                                                    "VALIDATION_EXTRA_PARAM" => ""),
    );

    $contenidoModulo="";
    $smarty->assign("REQUIRED_FIELD", _tr("Required field"));
    $smarty->assign("CANCEL", _tr("Cancel"));
    $smarty->assign("APPLY_CHANGES", _tr("Apply changes"));
    $smarty->assign("SAVE", _tr("Save"));
    $smarty->assign("EDIT", _tr("Edit"));
    $smarty->assign("DELETE", _tr("Delete"));
    $smarty->assign("CONFIRM_CONTINUE", _tr("Are you sure you wish to continue?"));
    $smarty->assign("icon","images/user.png");
    $smarty->assign("title_webmail", _tr("Mail Profile"));
    if(isset($_POST['submit_create_user'])) {
        // Implementar
        include_once("libs/paloSantoForm.class.php");
        $arrFillUser['description'] = '';
        $arrFillUser['name']        = '';
        $arrFillUser['group']       = '';
        $arrFillUser['extension']   = '';
        $arrFillUser['password1']   = '';
        $arrFillUser['password2']   = '';
        $oForm = new paloForm($smarty, $arrFormElements);
        $contenidoModulo=$oForm->fetchForm("$local_templates_dir/new.tpl", _tr("New User"),$arrFillUser);

    } else if(!is_null(getParameter("edit"))) {
	$contenidoModulo = editUser($userAccount,$pACL,$pDB,$arrFormElements,$smarty,$local_templates_dir,$idUserAccount,$userLevel1);

    } else if(isset($_POST['submit_save_user'])) {

        include_once("libs/paloSantoForm.class.php");

        $oForm = new paloForm($smarty, $arrFormElements);

        if($oForm->validateForm($_POST)) {
            // Exito, puedo procesar los datos ahora.
            $pACL = new paloACL($pDB);

            if((empty($_POST['password1']) or ($_POST['password1']!=$_POST['password2']))) {
                // Error claves
                $smarty->assign("mb_message", _tr("The passwords are empty or don't match"));
                $contenidoModulo=$oForm->fetchForm("$local_templates_dir/new.tpl", _tr("New User"), $_POST);
            } else {

                if($userLevel1=="admin"){
                    // Creo al usuario
                    $md5_password = md5($_POST['password1']);
                    $pACL->createUser($_POST['name'], $_POST['description'], $md5_password,$_POST['extension']);

                    $idUser = $pACL->getIdUser($_POST['name']);

                    // Versiones viejas del archivo acl.db tienen una fila con una
                    // tupla que asocia al usuario inexistente con ID 2, con el
                    // grupo 2 (Operadores). Se limpia cualquier membresía extraña.
                    $listaMembresia = $pACL->getMembership($idUser);
                    if (is_array($listaMembresia) && count($listaMembresia) > 0) {
                        foreach ($listaMembresia as $idGrupo) {
                            $pACL->delFromGroup($idUser, $idGrupo);
                        }
                    }

                    // Creo la membresia
                    $pACL->addToGroup($idUser, $_POST['group']);

                    $bExito = TRUE;
                    if (empty($pACL->errMsg)) {
                        $nuevasPropiedades = array();
                        if (!empty($_POST['webmailuser'])) $nuevasPropiedades['login'] = $_POST['webmailuser'];
                        if (!empty($_POST['webmailpassword1'])) $nuevasPropiedades['password'] = $_POST['webmailpassword1'];
                        if (!empty($_POST['webmaildomain'])) $nuevasPropiedades['domain'] = $_POST['webmaildomain'];
                        $bExito = actualizarPropiedades($pDB, $smarty, $idUser, 'webmail', 'default', $nuevasPropiedades);
                    }

                    if(!empty($pACL->errMsg)) {
                        // Ocurrio algun error aqui
                        $smarty->assign("mb_message", "ERROR: $pACL->errMsg");
                        $contenidoModulo=$oForm->fetchForm("$local_templates_dir/new.tpl", _tr("New User"), $_POST);
                    } else if ($bExito) {
                        header("Location: ?menu=userlist");
                    }
                }else{
                     $smarty->assign("mb_message", _tr("userNoAllowed"));
                }
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
            $contenidoModulo=$oForm->fetchForm("$local_templates_dir/new.tpl", _tr("New User"), $_POST);
        }

    } else if(isset($_POST['submit_apply_changes'])) {

	$arrayContent = applyChanges($userAccount,$pACL,$smarty,$idUserAccount,$userLevel1,$arrFormElements,$pDB,$local_templates_dir,$idUserInt,$extOther);

	if(isset($arrayContent["mb_title"]) && isset($arrayContent["mb_message"])){
	    $smarty->assign("mb_title",$arrayContent["mb_title"]);
	    $smarty->assign("mb_message",$arrayContent["mb_message"]);
	}

	if ($arrayContent["success"])
	    header("Location: ?menu=userlist");
	else{
	    if(isset($arrayContent["id_user"]))
		$smarty->assign("id_user", $_POST['id_user']);
	    if(isset($arrayContent["fill_user"]))
		$contenidoModulo = $arrayContent["form"]->fetchForm("$local_templates_dir/new.tpl", _tr("Edit User"), $arrayContent["fill_user"]);
	    else
		$contenidoModulo = $arrayContent["content"];
	}
    } else if(isset($_GET['action']) && $_GET['action']=="view") {
        if(!$pACL->isUserAdministratorGroup($userAccount)){
            if($pACL->getIdUser($userAccount) != $_GET['id']){
                $smarty->assign("mb_title",_tr("ERROR"));
                $smarty->assign("mb_message",_tr("You are not authorized to access to information of that user"));
                return reportUserList($pACL, $idUserAccount, $smarty, $userLevel1, $userAccount);
            }
        }
        include_once("libs/paloSantoForm.class.php");

        $oForm = new paloForm($smarty, $arrFormElements);

        //- TODO: Tengo que validar que el id sea valido, si no es valido muestro un mensaje de error

        $oForm->setViewMode(); // Esto es para activar el modo "preview"
        $arrUser = $pACL->getUsers($_GET['id']);

        // Conversion de formato
        $arrTmp['name']        = $arrUser[0][1];
        $arrTmp['description'] = $arrUser[0][2];
        $arrTmp['password1'] = "****";
        $arrTmp['password2'] = "****";
        $arrTmp['extension'] = $arrUser[0][3];
        //- TODO: Falta llenar el grupo
        $arrMembership  = $pACL->getMembership($_GET['id']);
        $id_group="";
        if(is_array($arrMembership)) {
            foreach($arrMembership as $groupName=>$groupId) {
                $id_group =  $groupId;
                // Asumo que cada usuario solo puede pertenecer a un grupo
                break;
            }
        }
        $arrTmp['group'] = $id_group;

        $listaPropiedades = leerPropiedadesWebmail($pDB, $smarty, $_GET['id']);
        if (isset($listaPropiedades['login'])) $arrTmp['webmailuser'] = $listaPropiedades['login'];
        if (isset($listaPropiedades['domain'])) $arrTmp['webmaildomain'] = $listaPropiedades['domain'];
        if (isset($listaPropiedades['password'])) $arrTmp['webmailpassword1'] = '****';
        //if (isset($listaPropiedades['imapsvr'])) $arrTmp['webmailimapsvr'] = $listaPropiedades['imapsvr'];

        $smarty->assign("id_user", $_GET['id']);
        $contenidoModulo=$oForm->fetchForm("$local_templates_dir/new.tpl", _tr("View User"), $arrTmp); // hay que pasar el arreglo

    }  else if(getParameter('action')=="edit_userExtension"){
	$smarty->assign("editUserExtension","yes");
	$html = editUser($userAccount,$pACL,$pDB,$arrFormElements,$smarty,$local_templates_dir,$idUserAccount,$userLevel1);
	$smarty->assign("CONTENT", $html);
	$smarty->assign("THEMENAME", $arrConf['mainTheme']);
	$smarty->assign("MODULE_NAME", $module_name);
	$smarty->assign("path", "");
	$contenidoModulo = $smarty->display("$local_templates_dir/edit_userExtension.tpl");
    } else if(getParameter('action')=="apply_changes_UserExtension"){
	include_once("libs/paloSantoJSON.class.php");
	$jsonObject = new PaloSantoJSON();
	$result = applyChanges($userAccount,$pACL,$smarty,$idUserAccount,$userLevel1,$arrFormElements,$pDB,$local_templates_dir,$idUserInt,$extOther);
	$arrMessage["mb_title"] = (isset($result["mb_title"]))?$result["mb_title"]:null;
	$arrMessage["mb_message"] = (isset($result["mb_message"]))?$result["mb_message"]:null;
	$arrMessage["success"] = $result["success"];
	$jsonObject->set_message($arrMessage);
	$contenidoModulo = $jsonObject->createJSON();
    } else {
        $contenidoModulo = reportUserList($pACL, $idUserAccount, $smarty, $userLevel1, $userAccount);
    }

    return $contenidoModulo;
}

function putHEAD_JQUERY_HTML($smarty)
{
    $documentRoot = $_SERVER["DOCUMENT_ROOT"];
    // include file of framework
    $HEADER_LIBS_JQUERY = "";
    $JQqueryDirectory = "$documentRoot/libs/js/jquery";
    // it to load libs JQuery
    if(is_dir($JQqueryDirectory)){
	$directoryScrips = "$documentRoot/libs/js/jquery/";
	if(is_dir($directoryScrips)){
	    $arr_js = obtainFiles($directoryScrips,"js");
	    if($arr_js!=false && count($arr_js)>0){
		for($i=0; $i<count($arr_js); $i++){
		    $dir_script = "libs/js/jquery/".$arr_js[$i];
		    $HEADER_LIBS_JQUERY .= "\n<script type='text/javascript' src='$dir_script'></script>";
		}
	    }
	}

	// FIXED: The css ui-lightness shouldn't be static.
	$directoryCss = "$documentRoot/libs/js/jquery/css/ui-lightness/";
	if(is_dir($directoryCss)){
	    $arr_css = obtainFiles($directoryCss,"css");
	    if($arr_css!=false && count($arr_css)>0){
		for($i=0; $i<count($arr_css); $i++){
		    $dir_css = "libs/js/jquery/css/ui-lightness/".$arr_css[$i];
		    $HEADER_LIBS_JQUERY .= "\n<link rel='stylesheet' href='$dir_css' />";
		}
	    }
	}
	//$HEADER_LIBS_JQUERY
    }
    $smarty->assign("HEADER_LIBS_JQUERY",$HEADER_LIBS_JQUERY);
}

function obtainFiles($dir,$type)
{
    $files =  glob($dir."/{*.$type}",GLOB_BRACE);
    $names ="";
    foreach ($files as $ima)
	$names[]=array_pop(explode("/",$ima));
    if(!$names) return false;
    return $names;
}

function applyChanges($userAccount,$pACL,$smarty,$idUserAccount,$userLevel1,$arrFormElements,$pDB,$local_templates_dir,$idUserInt,$extOther)
{

    $result = array();
    $result["mb_title"] = null;
    $result["mb_message"] = null;
    $result["id_user"] = null;
    $result["fill_user"] = null;
    if(!$pACL->isUserAdministratorGroup($userAccount)){
	if($pACL->getIdUser($userAccount) != $_POST['id_user']){
	   $result["mb_title"] = _tr("ERROR");
	   $result["mb_message"] = _tr("You are not authorized to access to information of that user");
	   $result["content"] = reportUserList($pACL, $idUserAccount, $smarty, $userLevel1, $userAccount);
	   $result["success"] = false;
	   return $result;
	}
    }
    $arrUser = $pACL->getUsers($_POST['id_user']);
    $username = $arrUser[0][1];
    $description = $arrUser[0][2];
    $arrFormElements['password1']['REQUIRED']='no';
    $arrFormElements['password2']['REQUIRED']='no';
    include_once("libs/paloSantoForm.class.php");

    $oForm = new paloForm($smarty, $arrFormElements);
    $result["form"] = $oForm;
    // Leer valores originales de propiedades
    $listaPropiedades = leerPropiedadesWebmail($pDB, $smarty, $_POST['id_user']);

    $oForm->setEditMode();
    if($oForm->validateForm($_POST)) {

	if((!empty($_POST['password1']) && ($_POST['password1']!=$_POST['password2']))) {
	    // Error claves
	    $result["mb_title"] = _tr("Validation Error");
	    $result["mb_message"] = _tr("The passwords are empty or don't match");
	    $arrFillUser['description'] = $_POST['description'];
	    $arrFillUser['name']        = $username;
	    $arrFillUser['group']       = $_POST['group'];
	    $arrFillUser['extension']   = isset($_POST['extension'])?$_POST['extension']:"";

	    if (isset($listaPropiedades['login'])) $arrFillUser['webmailuser'] = $listaPropiedades['login'];
	    if (isset($listaPropiedades['domain'])) $arrFillUser['webmaildomain'] = $listaPropiedades['domain'];
	    if (isset($listaPropiedades['password'])) $arrFillUser['webmailpassword1'] = $listaPropiedades['password'];
	    $result["id_user"] = $_POST["id_user"];
	    $result["fill_user"] = $arrFillUser;
	    $result["success"] = false;
	    return $result;
	} else {

	    // Exito, puedo procesar los datos ahora.
	    if($userLevel1!="admin"){
		$_POST['id_user'] = $idUserInt;
	    }
	    // Lleno el grupo
	    $arrMembership  = $pACL->getMembership($_POST['id_user']);
	    $id_group="";
	    if(is_array($arrMembership)) {
		foreach($arrMembership as $groupName=>$groupId) {
		    $id_group =  $groupId;
		    // Asumo que cada usuario solo puede pertenecer a un grupo
		    break;
		}
	    }

	    // El usuario trato de cambiar de grupo
	    if($id_group!=$_POST['group']) {
		if($userLevel1=="admin"){
		    $pACL->delFromGroup($_POST['id_user'], $id_group);
		    $pACL->addToGroup($_POST['id_user'], $_POST['group']);
		}
	    }

	    //- La updateUser no es la adecuada porque pide el username. Deberia
	    //- hacer una que no pida username en la proxima version

	    if($userLevel1=="admin")
		$_POST['extension'] = isset($_POST['extension'])?$_POST['extension']:"";
	    else
		$_POST['extension'] = $extOther;

	    $pACL->updateUser($_POST['id_user'], $username, $_POST['description'],$_POST['extension']);
	    //si se ha puesto algo en passwor se actualiza el password
	    if ((!empty($_POST['password1'])) && ($_POST['password1'] != '********')){
			$resultOp = $pACL->changePassword($_POST['id_user'], md5($_POST['password1']));
			if($resultOp){
				$uidCurrent = $pACL->getIdUser($userAccount);
				if($_POST['id_user'] === $uidCurrent)
					$_SESSION['elastix_pass'] = md5($_POST['password1']);
			}
		}

	    $nuevasPropiedades = array(
		'login'     =>  $_POST['webmailuser'],
		'domain'    =>  $_POST['webmaildomain'],
		'password'  =>  $_POST['webmailpassword1'],
		//'imapsvr'   =>  $_POST['']
	    );

	    if (empty($_POST['webmailpassword1'])) unset($nuevasPropiedades['password']);
        if ((!empty($_POST['webmailpassword1'])) && ($_POST['webmailpassword1'] == '********')){
            $nuevasPropiedades['password'] = $listaPropiedades['password'];
        }
	    $bExito = actualizarPropiedades($pDB, $smarty, $_POST['id_user'], 'webmail', 'default', $nuevasPropiedades);
	    $result["success"] = true;
	    return $result;
	}

    } else {
	// Manejo de Error
	$result["mb_title"] = _tr("Validation Error");
	$arrErrores=$oForm->arrErroresValidacion;
	$strErrorMsg = "<b>"._tr('The following fields contain errors').":</b><br>";
	foreach($arrErrores as $k=>$v) {
	    $strErrorMsg .= "$k, ";
	}
	$strErrorMsg .= "";
	$result["mb_message"] = $strErrorMsg;

	$arrFillUser['description'] = $_POST['description'];
	$arrFillUser['name']        = $username;
	$arrFillUser['group']       = $_POST['group'];
	$arrFillUser['extension']   = $_POST['extension'];
	foreach (array('webmailuser', 'webmaildomain', 'webmailpassword1') as $key)
	    $arrFillUser[$key] = $_POST[$key];
	$result["id_user"] = $_POST['id_user'];
	$result["fill_user"] = $arrFillUser;
	$result["success"] = false;
	return $result;
	/////////////////////////////////
    }
}

function editUser($userAccount,$pACL,$pDB,$arrFormElements,$smarty,$local_templates_dir,$idUserAccount,$userLevel1)
{
    if(getParameter("id_user")){
	$id_user = getParameter("id_user");
	if(!$pACL->isUserAdministratorGroup($userAccount)){
            if($pACL->getIdUser($userAccount) != $id_user){
                $smarty->assign("mb_title",_tr("ERROR"));
                $smarty->assign("mb_message",_tr("You are not authorized to access to information of that user"));
                return reportUserList($pACL, $idUserAccount, $smarty, $userLevel1, $userAccount);
            }
        }
    }
    else
	$id_user = $pACL->getIdUser($userAccount);
    // Tengo que recuperar la data del usuario
    $pACL = new paloACL($pDB);

    $arrUser = $pACL->getUsers($id_user);

    $arrFillUser['name'] = $arrUser[0][1];
    $arrFillUser['description'] = $arrUser[0][2];

    // Lleno el grupo
    $arrMembership  = $pACL->getMembership($id_user);
    $id_group="";
    if(is_array($arrMembership)) {
	foreach($arrMembership as $groupName=>$groupId) {
	    $id_group =  $groupId;
	    // Asumo que cada usuario solo puede pertenecer a un grupo
	    break;
	}
    }
    $arrFillUser['group'] = $id_group;
    $arrFillUser['extension'] = $arrUser[0][3];

    // Implementar
    include_once("libs/paloSantoForm.class.php");
    $arrFormElements['password1']['REQUIRED']='no';
    $arrFormElements['password2']['REQUIRED']='no';
    $oForm = new paloForm($smarty, $arrFormElements);

    $arrFillUser['password1']='********';
    $arrFillUser['password2']='********';

    $listaPropiedades = leerPropiedadesWebmail($pDB, $smarty, $id_user);
    if (isset($listaPropiedades['login'])) $arrFillUser['webmailuser'] = $listaPropiedades['login'];
    if (isset($listaPropiedades['domain'])) $arrFillUser['webmaildomain'] = $listaPropiedades['domain'];
    if (isset($listaPropiedades['password'])) $arrFillUser['webmailpassword1'] = '********';
    //if (isset($listaPropiedades['imapsvr'])) $arrFillUser['webmailimapsvr'] = $listaPropiedades['imapsvr'];

    $oForm->setEditMode();
    $smarty->assign("id_user", $id_user);
    return $oForm->fetchForm("$local_templates_dir/new.tpl", ""._tr('Edit User')." \"" . $arrFillUser['name'] . "\"", $arrFillUser);
}

function reportUserList($pACL, $idUserAccount, $smarty, $userLevel1, $userAccount)
{
    if (isset($_POST['delete'])) {
        //- TODO: Validar el id de user
        if($userLevel1=="admin"){
            if(isset($_POST['id_user']) && $_POST['id_user']=='1') {
                // No se puede elimiar al usuario admin
                $smarty->assign("mb_title", _tr("ERROR"));
                $smarty->assign("mb_message", _tr("The admin user cannot be deleted because is the default Elastix administrator. You can delete any other user."));
            } else {
                $pACL->deleteUser($_POST['id_user']);
            }
        }else{
            $smarty->assign("mb_message", _tr("userNoAllowed"));
        }
    }

    $nav   = getParameter("nav");
    $start = getParameter("start");

    $total = $pACL->getNumUsers();
    $total = ($total == NULL)?0:$total;

    $limit  = 20;
    $oGrid  = new paloSantoGrid($smarty);
    $oGrid->setLimit($limit);
    $oGrid->setTotal($total);
    $oGrid->pagingShow(true);
    $oGrid->setURL("?menu=userlist");
    $offset = $oGrid->calculateOffset();
    $end = $oGrid->getEnd();

    $arrUsers = $pACL->getUsersPaging($limit, $offset);

    $arrData = array();
    $typeUser = "";
    foreach($arrUsers as $user) {
        $arrMembership  = $pACL->getMembership($user[0]);

        $group="";
        if(is_array($arrMembership)) {
            foreach($arrMembership as $groupName=>$groupId) {
                if($groupName == 'administrator')
                    $groupName = _tr('administrator');
                else if($groupName == 'operator')
                    $groupName = _tr('operator');
                else if($groupName == 'extension')
                    $groupName = _tr('extension');

                $group .= ucfirst($groupName) . " ";
            }
        }
        $arrTmp    = array();
        //$arrTmp[0] = "&nbsp;<a href='?menu=usernew&action=view&id=" . $user['id'] . "'>" . $user['name'] . "</a>";
        //$arrTmp[1] = $user['description'];
        if($idUserAccount){
            $arrTmp[0] = "&nbsp;<a href='?menu=userlist&action=view&id=" . $user[0] . "'>" . htmlentities($user[1], ENT_COMPAT, 'UTF-8') . "</a>";
            $arrTmp[1] = htmlentities($user[2], ENT_COMPAT, 'UTF-8');
            $arrTmp[2] = htmlentities($group, ENT_COMPAT, 'UTF-8');
            if( ($user[3] == '') || is_null($user[3]) )
                $arrTmp[3] = _tr("No extension associated");
            else
                $arrTmp[3] = htmlentities($user[3], ENT_COMPAT, 'UTF-8');
            $arrData[] = $arrTmp;
            $smarty->assign("usermode","admin");
            $typeUser = "admin";
            $end++;
        }else{
            if($user[1] == $userAccount){
                $arrTmp[0] = "&nbsp;<a href='?menu=userlist&action=view&id=" . $user[0] . "'>" . htmlentities($user[1], ENT_COMPAT, 'UTF-8') . "</a>";
                $arrTmp[1] = htmlentities($user[2], ENT_COMPAT, 'UTF-8');
                $arrTmp[2] = htmlentities($group, ENT_COMPAT, 'UTF-8');
                if( ($user[3] == '') || is_null($user[3]) )
                    $arrTmp[3] = _tr("No extension associated");
                else
                    $arrTmp[3] = htmlentities($user[3], ENT_COMPAT, 'UTF-8');
                $arrData[] = $arrTmp;
                $smarty->assign("usermode","other");
                $typeUser = "other";
                $end++;
            }
        }

    }
    $arrGrid = array("title"    => _tr("User List"),
                        "icon"     => "images/user.png",
                        "columns"  => array(0 => array("name"      => _tr("Login"),
                                                    "property1" => ""),
                                            1 => array("name"      => _tr("Real Name"),
                                                    "property1" => ""),
                                            2 => array("name"      => _tr("Group"),
                                                    "property1" => ""),
                                            3 => array("name"      => _tr("Extension"),
                                                    "property1" => "")
                                        )
                    );

    if(!($typeUser == "other"))
      $oGrid->addNew("submit_create_user",_tr("Create New User"));

    $contenidoModulo = $oGrid->fetchGrid($arrGrid, $arrData);
    return $contenidoModulo;
}

function leerPropiedadesWebmail(&$pDB, &$smarty, $idUser)
{
    // Obtener la información del usuario con respecto al perfil "default" del módulo "webmail"
    $pACL = new paloACL($pDB);
    $listaPropiedades = $pACL->getUserProfile($idUser, 'webmail');
    if (!is_array($listaPropiedades)) {
        print "ERROR DE DB: ".$pACL->errMsg;
        $listaPropiedades = array();
    }

    return $listaPropiedades;
}

function actualizarPropiedades(&$pDB, &$smarty, $idUser, $sModulo, $sPerfil, $propiedades)
{
    $pACL = new paloACL($pDB);
    $r = $pACL->saveUserProfile($idUser, $sModulo, $propiedades, $sPerfil);
    if (!$r) {
        $smarty->assign("mb_message", "ERROR DE DB: ".$pACL->errMsg);
        return FALSE;
    }
    return TRUE;
}
