<?php
/* vim: set expandtab tabstop=4 softtabstop=4 shiftwidth=4:
  Codificación: UTF-8
  +----------------------------------------------------------------------+
  | Issabel version 4.0.0                                                |
  | http://www.issabel.org                                               |
  +----------------------------------------------------------------------+
  | Copyright (c) 2017 Issabel Foundation                                |
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
  | The Initial Developer is Issabel Foundation                          |
  +----------------------------------------------------------------------+
*/
$module_name=basename(getcwd());
$documentRoot = $_SERVER["DOCUMENT_ROOT"];
include_once "$documentRoot/libs/paloSantoDB.class.php";
include_once "$documentRoot/libs/paloSantoACL.class.php";
include_once "$documentRoot/modules/$module_name/configs/default.conf.php";
session_name("issabelSession");
session_start();
$issabel_user = (isset($_SESSION["issabel_user"]))?$_SESSION["issabel_user"]:null;
$pDB = new paloDB("sqlite3:////var/www/db/acl.db");
$pACL = new paloACL($pDB);
$isUserAuth = $pACL->isUserAuthorized($issabel_user,"access",$module_name);
unset($_SESSION);
session_commit();
if(!$isUserAuth) { die('Unauthorized'); }

$backup_dir = $arrConfModule['dir'];


if (isset($_REQUEST['filename'])){
    $filename = escapeshellarg($_REQUEST['filename']);
    $filename = substr($filename,1,-1);
    $filename = $backup_dir."/".$filename;
    if(is_file($filename)) { 
        echo "<div style='font-family: \"Lucida Console\", Monaco, monospace'>";
    
        $dahdi = "";
        $cmd   = "/usr/bin/issabel-helper migration $dahdi $filename";
        $cmd .= " 2>&1 || echo \"err_flag\"";

        $file = popen($cmd,"r");
        while(!feof($file)) {
            $line = fgets($file);
            if($line == "err_flag\n") {
                echo "Error!\n";
                $error = true;
                break;
            }
            echo $line."<br>";
            ob_flush();
            flush();
        }
        pclose($file);
        echo "</div>";
        echo "<script>alert('Migration Complete');</script>";
    } else {
        echo "$filename is not a file";
    }
}

