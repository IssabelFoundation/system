<?php
/*
vim: set expandtab tabstop=4 softtabstop=4 shiftwidth=4:
 Codificación: UTF-8
  +----------------------------------------------------------------------+
  | Issabel version 0.5                                                  |
  | http://www.issabel.org                                               |
  +----------------------------------------------------------------------+
  | Copyright (c) 2006 Palosanto Solutions S. A.                         |
  | Copyright (c) 1997-2003 Palosanto Solutions S. A.                    |
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
  | Autor: Luis Abarca Villacís <labarca@palosanto.com>                  |
  +----------------------------------------------------------------------+
  | The Initial Developer of the Original Code is PaloSanto Solutions    |
  +----------------------------------------------------------------------+
  $Id: QueryRpms.class.php,v 1.0 2013/12/10 12:40:22 Luis Abarca Exp $
*/

$documentRoot = $_SERVER["DOCUMENT_ROOT"];
require_once "$documentRoot/libs/REST_Resource.class.php";
require_once "$documentRoot/libs/paloSantoJSON.class.php";
require_once "$documentRoot/modules/packages/libs/rpm.class.php";
/*
 *   REST que permite consultar si un determinado grupo de RPMs esta instalado en el sistema.
 *   Generando un resultado:
 *   Si esta instalado:          -->         {"Name":"issabel-framework","Version":"2.4.0","Release":"1"}
 *   Si no esta instalado:       -->         {"Name":"issabel-lcdissabel","Status":"Not Installed"}
*/
/*
 * Para esta implementación de REST, se tienen los siguientes URIs:
 *
 *  /QueryRPMs            application/json
 *      GET     lista las opciones de URIs disponibles para las diferentes consultas especificadas.
 *  /QueryRPMs/listall   application/json
 *      GET     lista un reporte de todos los rpms de la familia Issabel, que esten o no esten
 *              instalados actualmente en su sistema.
 *  /QueryRPMs/onlyone/XXXX application/json
 *      GET     reporta el status del rpm cuyo nombre es XXXX.
 *  /QueryRPMs/installed   application/json
 *      GET     lista un reporte de todos los rpms Issabel actualmente instalados.
 *  /QueryRPMs/notinstalled application/json
 *      GET     lista un reporte de todos los rpms Issabel que no estan instalados actualmente.
 */

class QueryRPMs
{
    private $resourcePath;
    function __construct($resourcePath)
    {
	    $this->resourcePath = $resourcePath;
    }

    function URIObject()
    {
	$uriObject = NULL;
	if (count($this->resourcePath) <= 0) {
		$uriObject = new RpmBase();
	} elseif (in_array($this->resourcePath[0], array('listall', 'onlyone','notinstalled','installed'))) {
	    switch (array_shift($this->resourcePath)) {
	    case 'listall':
            $uriObject = (count($this->resourcePath) <= 0)
		    ? new ListAll("correct")
		    : new ListAll("incorrect");
		break;

	    case 'notinstalled':
		    if(count($this->resourcePath) <= 0)
		        $uriObject = new NotInstalled();
		break;

        case 'installed':
            if(count($this->resourcePath) <= 0)
                $uriObject = new Installed();
        break;

        case 'onlyone':
            if( (count($this->resourcePath) > 0 ) && (count($this->resourcePath) < 2 ) )
                $uriObject = new OnlyOne(array_shift($this->resourcePath));
        break;
	    }
	}
	if(count($this->resourcePath) > 0)
	    return NULL;
	else
	    return $uriObject;
    }
}

class RpmBase extends REST_Resource
{
	function HTTP_GET()
    {
    	$json = new Services_JSON();
        return $json->encode(array(
            'url_listall'  =>  '/rest.php/packages/QueryRPMs/listall',
            'url_onlyone'  =>  '/rest.php/packages/QueryRPMs/onlyone',
            'url_notinstalled'  =>  '/rest.php/packages/QueryRPMs/notinstalled',
            'url_installed'  =>  '/rest.php/packages/QueryRPMs/installed'));
    }
}

class ListAll extends REST_Resource
{

	function __construct($sLength)
    {
        $this->_length = $sLength;
    }

    function HTTP_GET()
    {
        $cq = new core_QueryRpms();
        $out = $cq->listall($this->_length);
        $json = new Services_JSON();
        return $json->encode($out);
    }
}

class NotInstalled extends REST_Resource
{
    function HTTP_GET()
    {
        $cq = new core_QueryRpms();
        $out = $cq->notinstalled();
        $json = new Services_JSON();
        return $json->encode($out);
    }
}

class Installed extends REST_Resource
{
    function HTTP_GET()
    {
        $cq = new core_QueryRpms();
        $out = $cq->installed();
        $json = new Services_JSON();
        return $json->encode($out);
    }
}

class OnlyOne extends REST_Resource
{

	function __construct($sRpmName)
    {
        $this->_rpmName = $sRpmName;
    }

    function HTTP_GET()
    {
        $cq = new core_QueryRpms();
        $out = $cq->onlyone($this->_rpmName);
        if(!is_array($out)){
            $json = new paloSantoJSON();
            $error = $cq->getError();
            header("HTTP/1.1 400 Bad Request");
            $json->set_status("ERROR");
            $json->set_error($error);
            return $json->createJSON();
        }else{
        $json = new Services_JSON();
        return $json->encode($out);
        }
    }
}

?>
