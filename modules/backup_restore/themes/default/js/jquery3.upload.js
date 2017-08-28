
function confirm_upload(obj) {

    var filesize = 0;
    var Sys = {};

    if(navigator.userAgent.indexOf("MSIE")>0){
        Sys.ie=true;
    } else {
        Sys.notid=true;
    }

    if(typeof obj.files[0] == 'undefined') { 
        return false;
    }

    if(Sys.notie){
        filesize = obj.files[0].size;
    } else if(Sys.ie) {
        try {
            obj.select();
            var realpath   = document.selection.createRange().text;
            var fileobject = new ActiveXObject ("Scripting.FileSystemObject");
            var file       = fileobject.GetFile (realpath);
            var filesize   = file.Size;
        } catch(e){
            alert("Please allow ActiveX Scripting File System Object!");
            return false;
        }
    }

    if(filesize > 3072*1024*1024) {
        alert("Maximum allowed file size is 3 GB");
        return false;
    }

    filename = obj.files[0].name;

    var res = filename.match(/([^-]*)-(\d{14})-([^\.]*).tar/);
    if(res === null) {
        var res = filename.match(/(\d{8})-(\d{6})-(\d{10})-(.*).tgz/);
	if(res === null) {
        	alert("Invalid file name");
        	return false;
	}
    }

    if (window.confirm("Are you sure?")) {
        var $hiddenInput = $('<input/>',{type:'hidden',name:'uploadbk',value:'uploadbk'});
        $hiddenInput.appendTo("#idformgrid");
        $("form#idformgrid" )
	.attr( "enctype", "multipart/form-data" )
	.attr( "encoding", "multipart/form-data" );
        document.getElementById('idformgrid').submit();
    }
}

