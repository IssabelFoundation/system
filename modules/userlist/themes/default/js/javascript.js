function apply_changes()
{
    var arrAction                     = new Array();
	arrAction["action"]           = "apply_changes_UserExtension";
	arrAction["menu"]             = "userlist";
	arrAction["group"]            = document.getElementById("group").value;
	arrAction["extension"]        = document.getElementById("extension").value;
	arrAction["description"]      = document.getElementsByName("description")[0].value;
	arrAction["password1"]        = document.getElementsByName("password1")[0].value;
	arrAction["password2"]        = document.getElementsByName("password2")[0].value;
	arrAction["webmailuser"]      = document.getElementsByName("webmailuser")[0].value;
	arrAction["webmaildomain"]    = document.getElementsByName("webmaildomain")[0].value;
	arrAction["webmailpassword1"] = document.getElementsByName("webmailpassword1")[0].value;
	arrAction["id_user"]          = document.getElementsByName("id_user")[0].value;
	arrAction["rawmode"]          = "yes";
	request("index.php",arrAction,false,
	    function(arrData,statusResponse,error)
	    {   
		if(arrData["success"]){
		    if (window.opener && !window.opener.closed) {
			window.opener.location.reload();
		    }
		    window.close();
		}
		else{
		    if(arrData["mb_title"] && arrData["mb_message"]){
			if(document.getElementById("table_error"))
			  document.getElementById("table_error").style.display='';
			else
			  document.getElementById("message_error").style.display='';
			document.getElementById("mb_title").innerHTML="&nbsp;" + arrData["mb_title"];
			document.getElementById("mb_message").innerHTML= arrData["mb_message"];
		    }
		}
	    }
	);
 
}