<?php
require_once "libs/paloSantoForm.class.php";

function _moduleContent(&$smarty, $module_name)
{
    //include module files
    require_once "modules/$module_name/configs/default.conf.php";

    load_language_module($module_name);

    //global variables
    global $arrConf;
    global $arrConfModule;
    $arrConf = array_merge($arrConf,$arrConfModule);

    //folder path for custom templates
    $base_dir = dirname($_SERVER['SCRIPT_FILENAME']);
    $templates_dir = (isset($arrConf['templates_dir'])) ? $arrConf['templates_dir'] : 'themes';
    $local_templates_dir = "$base_dir/modules/$module_name/".$templates_dir.'/'.$arrConf['theme'];
    
    if ($_POST){
        if($_POST['send'] == 'ping' && isset($_POST['ping_hostname'])) {
            $send="ping";
            $hostname=$_POST['ping_hostname'];
        } else if($_POST['send'] == 'tracepath' && isset($_POST['tracert_hostname'])) {
            $send="tracepath";
            $hostname=$_POST['tracert_hostname'];
        }
        $frame_url=$_SERVER['REQUEST_SCHEME']."://".$_SERVER['HTTP_HOST']."/modules/ping/generate.php?send=".$send."&hostname='".$hostname."'";
        $smarty->assign("frame_url", $frame_url);    
    }else{
        $smarty->assign("frame_url", "");    
    }
    
    $default_host="www.issabel.org";

    if(isset($_POST['ping_hostname'])) {
        $ping_hostname=trim($_POST['ping_hostname']);    
    }else{    
        $ping_hostname="$default_host";
    }
     $smarty->assign("ping_hostname", $ping_hostname);
     
    if(isset($_POST['tracert_hostname'])) {
        $tracert_hostname=trim($_POST['tracert_hostname']);    
    }else{    
        $tracert_hostname="$default_host";
    }
    $smarty->assign("tracert_hostname", $tracert_hostname);
    
    $content = $smarty->fetch("$local_templates_dir/new.tpl");
    
    return $content;
    
}
