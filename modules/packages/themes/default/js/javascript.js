function ejecutarPeticionPaquete(msg_wait, request_param)
{
    if ($("#estaus_reloj").val() != 'apagado') {
        alert(arrLang.action_in_progress);
        return;
    }

    $.get('index.php',{
        menu:       'registration',
        action:     'isRegistered',
        rawmode:    'yes'
    }, function(response) {
        var arrData = response.message;
        var statusResponse = response.statusResponse;
        var error = response.error;

        if (arrData["registered"] != "yes-all"){
            showPopupCloudLogin('',540,335);
            return;
        }

        $("#estaus_reloj").val('prendido');
        $("#relojArena").html("<img src='modules/packages/images/loading.gif' align='absmiddle' /> <br /> <font style='font-size:12px; color:red'>" + msg_wait + "</font>");

        // TODO: las siguientes 2 acciones parece que no hacen nada en temas Elastix recientes
        $("#neo-table-header-filterrow").data("neo-table-header-filterrow-status", "hidden");
        $("#neo-tabla-header-row-filter-1").click();

        request_param['menu'] = getCurrentElastixModule();
        request_param['rawmode'] = 'yes';
        $.post('index.php', request_param, function(response) {
            alert(response.statusResponse);
            $("#relojArena").html("");
            $("#estaus_reloj").val('apagado');
            $("#submit_nombre").click();
        },
        'json');
    });
}

function refreshPackageList()
{
    return ejecutarPeticionPaquete(
        arrLang.updating_repositories,
        {action: 'updateRepositories'});
}

function installaPackage(paquete, val)
{
    return ejecutarPeticionPaquete(
        (val == 0) ? arrLang.install_package : arrLang.update_package,
        {action: 'install', paquete: paquete, val: val});
}

function uninstallPackage(paquete)
{
    return ejecutarPeticionPaquete(
        arrLang.uninstall_package,
        {action: 'uninstall', paquete: paquete});
}

function confirmUpdate(paquete)
{
    if (confirm(arrLang.msg_confirm_update)) installaPackage(paquete, 1);
}

function confirmDelete(paquete)
{
    if (confirm(arrLang.msg_confirm_delete)) uninstallPackage(paquete);
}

