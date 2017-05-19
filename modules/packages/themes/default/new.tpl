    <table border='0' cellpadding='0' callspacing='0' width='100%' height='44'>
        <tr class="letra12">
            <td width='70%'>{$nombre_paquete.LABEL} &nbsp; {$nombre_paquete.INPUT}
                <input type='submit' class='button' id="submit_nombre" name='submit_nombre' value='{$Search}' />
            </td>
            <td rowspan='2' id='relojArena' style="text-align:center;">
            </td>
        </tr>
        <tr class="letra12">
            <td width='200'>{$submitInstalado.LABEL} &nbsp; {$submitInstalado.INPUT}</td>
        </tr>
    </table>
    <input type='hidden' id='estaus_reloj' value='apagado' />
{literal}
<script type='text/javascript'>
arrLang = {
    action_in_progress: "{/literal}{$accionEnProceso}{literal}",
    updating_repositories: "{/literal}{$UpdatingRepositories}{literal}",
    install_package: "{/literal}{$InstallPackage}{literal}",
    update_package: "{/literal}{$UpdatePackage}{literal}",
    uninstall_package: "{/literal}{$UninstallPackage}{literal}",
    msg_confirm_delete: "{/literal}{$msgConfirmDelete}{literal}",
    msg_confirm_update: "{/literal}{$msgConfirmUpdate}{literal}"
};
</script>

{/literal}
