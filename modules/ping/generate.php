<?php 

if ($_REQUEST){

    if($_REQUEST['send'] == "Ping" && isset($_REQUEST["hostname"])) {

        $ping_host = escapeshellcmd($_REQUEST['hostname']);
        $cmd = "/usr/bin/ping -c 4 $ping_host";            

    } else if($_REQUEST['send'] == 'Tracepath' && isset($_REQUEST['hostname'])) {
        $tracert_host = escapeshellcmd($_REQUEST['hostname']);
        $cmd = "tracepath $tracert_host";            
    }else{
        //
    }
        
    $cmd .= " 2>&1 || echo \"err_flag\"";
        
    $file = popen($cmd,"r");
        while(!feof($file)) {
            $line = fgets($file);
            if($line == "err_flag\n") {
                $error = true;
                break;
            }
            echo $line."<br>";
            
            ob_flush();
            flush();
        }
        pclose($file);

}

?>
