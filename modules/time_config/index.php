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

require_once "libs/misc.lib.php";

function _moduleContent(&$smarty, $module_name)
{
    //include module files
    include_once "libs/paloSantoForm.class.php" ;
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



    $smarty->assign("TIME_TITULO",_tr("Date and Time Configuration"));
    $smarty->assign("INDEX_HORA_SERVIDOR",_tr("Current Datetime"));
    $smarty->assign("TIME_NUEVA_FECHA",_tr("New Date"));
    $smarty->assign("TIME_NUEVA_HORA",_tr("New Time"));
    $smarty->assign("TIME_NUEVA_ZONA",_tr("New Timezone"));
    $smarty->assign("INDEX_ACTUALIZAR",_tr("Apply changes"));
    $smarty->assign("TIME_MSG_1", _tr("The change of date and time can concern important  system processes.").'  '._tr("Are you sure you wish to continue?"));

    $arrForm = array(
    );
    $oForm = new paloForm($smarty, $arrForm);

/*
	Para cambiar la zona horaria:
	1)	Abrir y mostrar columna 3 de /usr/share/zoneinfo/zone.tab que muestra todas las zonas horarias.
	2)	Al elegir fila de columna 3, verificar que sea de la forma abc/def y que
		existe el directorio /usr/share/zoneinfo/abc/def . Pueden haber N elementos
		en la elección, separados por / , incluyendo uno solo (sin / alguno)
	3)	Si existe /etc/localtime, borrarlo
	4)	Copiar archivo /usr/share/zoneinfo/abc/def a /etc/localtime
	5)	Si existe /var/spool/postfix/etc/localtime , removerlo y sobreescribr
		con el mismo archivo copiado a /etc/localtime

	Luego de esto, ejecutar cambio de hora local

*/
	// Abrir el archivo /usr/share/zoneinfo/zone.tab y cargar la columna 3
	// Se ignoran líneas que inician con #
	$listaZonas = NULL;
	$hArchivo = fopen('/usr/share/zoneinfo/zone.tab', 'r');
	if ($hArchivo) {
		$listaZonas = array();
		while ($tupla = fgetcsv($hArchivo, 2048, "\t")) {
			if (count($tupla) >= 3 && $tupla[0]{0} != '#') $listaZonas[] = $tupla[2];
		}
		fclose($hArchivo);
		sort($listaZonas);
	}

	// Cargar de /etc/sysconfig/clock la supuesta zona horaria configurada.
	// El resto de contenido del archivo se preserva, y la clave ZONE se
	// escribirá como la última línea en caso de actualizar
	$sZonaActual = get_default_timezone();  // <-- requiere elastix-framework >= 2.5.0-6

	if (isset($_POST['Actualizar'])) {
//		print '<pre>';print_r($_POST);print '</pre>';

        $date = getParameter("date");
        $date = translateDate($date);
        $date = explode("-",$date);
        $month = "";
        $year = "";
        $day = "";

        if(isset($date[0]) && isset($date[1]) && isset($date[2])){
            $month = $date[1];
            $day = $date[2];
            $year = $date[0];
        }
		// Validación básica
		$listaVars = array(
	//		'ServerDate_Year'	=>	'^[[:digit:]]{4}$',
	//		'ServerDate_Month'	=>	'^[[:digit:]]{1,2}$',
	//		'ServerDate_Day'	=>	'^[[:digit:]]{1,2}$',
			'ServerDate_Hour'	=>	'^[[:digit:]]{1,2}$',
			'ServerDate_Minute'	=>	'^[[:digit:]]{1,2}$',
			'ServerDate_Second'	=>	'^[[:digit:]]{1,2}$',
		);
		$bValido = TRUE;
		foreach ($listaVars as $sVar => $sReg) {
			if (!preg_match("/$sReg/", $_POST[$sVar])) {
				$bValido = FALSE;
			}
		}
        if(!preg_match('/^[[:digit:]]{4}$/',$year))
            $bValido = FALSE;
        if(!preg_match('/^[[:digit:]]{1,2}$/',$month))
            $bValido = FALSE;
        if(!preg_match('/^[[:digit:]]{1,2}$/',$day))
            $bValido = FALSE;
		if ($bValido && !checkdate($month, $day, $year)) $bValido = FALSE;

		// Validación de zona horaria nueva
		$sZonaNueva = $_POST['TimeZone'];
		if (!in_array($sZonaNueva, $listaZonas)) $sZonaNueva = $sZonaActual;

		if (!$bValido) {
			// TODO: internacionalizar
			$smarty->assign("mb_message", _tr('Date not valid'));
		} else {
            /* En caso de cambiar la zona horaria, el cambio debe de hacerse
             * DESPUÉS de setear la hora, porque el usuario espera que la hora
             * mostrada luego del cambio salte por la cantidad adecuada según
             * el cambio de zona. */
            if ($bValido) {
                $fecha = sprintf('%04d-%02d-%02d %02d:%02d:%02d',
                    $year, $month, $day, $_POST['ServerDate_Hour'],
                    $_POST['ServerDate_Minute'], $_POST['ServerDate_Second']);
                $cmd = "/usr/bin/elastix-helper dateconfig --datetime '$fecha' 2>&1";
                $output=$ret_val="";
                exec($cmd,$output,$ret_val);

                if ($ret_val == 0) {
                    $smarty->assign('mb_message', _tr('System time changed successfully'));
                } else {
                    $smarty->assign('mb_message', _tr('System time can not be changed')." - <br/>".implode('<br/>', $output));
                    $bValido = FALSE;
                }
            }

            if ($bValido && $sZonaNueva != $sZonaActual) {
                $sComando = '/usr/bin/elastix-helper dateconfig'.
                    ' --timezone '.escapeshellarg($sZonaNueva).
                    ' 2>&1';
                $output = $ret = NULL;
                exec($sComando, $output, $ret);
                if ($ret != 0) {
                    $smarty->assign('mb_message', _tr('Failed to change timezone').' - '.implode('<br/>', $output));
                    $bValido = FALSE;
                } else {
                    $sZonaActual = $sZonaNueva;

                    // Actualizar zona horaria para date()
                    date_default_timezone_set($sZonaActual);
                }
			}
		}
	}
    $sContenido = '';

    $mes = date("m",time());
    $mes = (int)$mes - 1;

    $smarty->assign("CURRENT_DATETIME", strftime("%Y,$mes,%d,%H,%M,%S",time()));
    $smarty->assign('LISTA_ZONAS', $listaZonas);
    $smarty->assign('ZONA_ACTUAL', $sZonaActual);
    $smarty->assign("CURRENT_DATE",strftime("%d %b %Y",time()));
    $smarty->assign("icon","modules/$module_name/images/system_preferences_datetime.png");
	$sContenido .= $oForm->fetchForm("$local_templates_dir/time.tpl", _tr('Date and Time Configuration'), $_POST);
	return $sContenido;
}

?>
