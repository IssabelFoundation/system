
{literal}
<script type="text/javascript">

function ChequearTodos(chkbox)
{
    for (var i=0;i < document.getElementById("backup_form").elements.length;i++)
    {
        var elemento = document.getElementById("backup_form").elements[i];
        if (elemento.type == "checkbox")
        {
            if(!elemento.disabled)
                elemento.checked = chkbox.checked
        }
    }
}
function ChequearTabla(chkbox, id)
{
    //Si desmarco el checkbox desmarcar all options global
    if(!chkbox.checked)
        document.getElementById('backup_total').checked = chkbox.checked;

    var arr_chk = document.getElementById(id).getElementsByTagName("INPUT");
    for(var i=0; i<arr_chk.length; i++)
    {
        if(!arr_chk[i].disabled)
            arr_chk[i].checked = chkbox.checked;
    }
}
function VerificarCheck(chkbox, id)
{
    if(!chkbox.checked)
    {
        //Descarmar all options de la tabla
        document.getElementById(id).checked = chkbox.checked;
        //Descarmar all options global
        document.getElementById('backup_total').checked = chkbox.checked;
    }
}
function popup_dif(content_popup)
{
	var ancho = 800;
        var alto = 110;
	var winiz = (screen.width-ancho)/2;
	var winal = (screen.height-alto)/2;	
	my_window = window.open(content_popup,"my_window","width="+ancho+",height="+alto+",top="+winal+",left="+winiz+",location=no,status=no,resizable=no,scrollbars=no,fullscreen=no,toolbar=no,directories=no");
        my_window.document.close();
}
</script>
{/literal}
<form method="POST" enctype="multipart/form-data" id="backup_form">
    <table width="99%" border="0" cellspacing="0" cellpadding="0" align="center">
        <tr>
            <td>
                <table width="100%" cellpadding="4" cellspacing="0" border="0">
                    <tr>
                        <td align="left">{$ERROR_MSG}</td>
                    </tr>
                    <tr>
                        <td align="left">
                            <input class="button" type="submit" name="process" value="{$PROCESS}">
                            <input class="button" type="submit" name="back" value="{$BACK}">
                        </td>
                    </tr>
                    <tr>
                        <td>{$WARNING}</td>
                    </tr>
                </table>
            </td>
        </tr>
        <tr>
            <td>
                <table width="99%" BORDER=0>
                    <tr>
                        <td colspan=4><INPUT type="checkbox" name="backup_total" id="backup_total" onClick=ChequearTodos(this);> <strong>{$LBL_TODOS}</strong></td>
                    </tr>
                    <tr>
                    <!-- ********** E N D   P O I N T ************ -->
                        <td width="25%">
                            <table id="table_endpoint" width="99%" height="100px" border="0" cellspacing="0" cellpadding="0" class="tabForm" style='display:table;'>
                                <tbody>
                                    <tr>
                                        <td><legend>{$ENDPOINT}</legend></td>
                                    </tr>
                                    <tr>
                                        <td><INPUT type="checkbox" name="backup_endpoint" id="backup_endpoint" onClick="ChequearTabla(this, 'table_endpoint');"> <strong>{$TODO_ENDPOINT}</strong></td>
                                    </tr>
                                    {foreach key=key item=item from=$backup_endpoint}
                                    <tr>
                                        <td><INPUT type="checkbox" {$item.disable} name="{$key}" id="{$key}" value="{$key}" onClick="VerificarCheck(this, 'backup_endpoint');" {$item.check}> <span {if !empty($item.disable)}style="text-decoration: line-through"{/if}>{$item.desc}&nbsp;{$item.msg}</span></td>
                                    </tr>
                                    {/foreach}
                                </tbody>
                            </table>
                        </td>
                    <!-- ********** F A X ************ -->
                        <td width="25%">
                            <table id="table_fax" width="99%" height="100px" border="0" cellspacing="0" cellpadding="0" class="tabForm" style='display:table;'>
                                <tbody>
                                    <tr>
                                        <td><legend>{$FAX}</legend></td>
                                    </tr>
                                    <tr>
                                        <td><INPUT type="checkbox" name="backup_fax" id="backup_fax" onClick="ChequearTabla(this, 'table_fax');"> <strong>{$TODO_FAX}</strong></td>
                                    </tr>
                                    {foreach key=key item=item from=$backup_fax}
                                    <tr>
                                        <td><INPUT type="checkbox" {$item.disable} name="{$key}" id="{$key}" value="{$key}" onClick="VerificarCheck(this, 'backup_fax');" {$item.check}> <span {if !empty($item.disable)}style="text-decoration: line-through"{/if}>{$item.desc}&nbsp;{$item.msg}<span></td>
                                    </tr>
                                    {/foreach}
                                </tbody>
                            </table>
                        </td>
                    <!-- ********** E M A I L ************ -->
                        <td width="25%">
                            <table id="table_email" width="99%" height="100px" border="0" cellspacing="0" cellpadding="0" class="tabForm" style='display:table;'>
                                <tbody>
                                    <tr>
                                        <td><legend>{$EMAIL}</legend></td>
                                    </tr>
                                    <tr>
                                        <td><INPUT type="checkbox" name="backup_email" id="backup_email" onClick="ChequearTabla(this, 'table_email');"> <strong>{$TODO_EMAIL}</strong></td>
                                    </tr>
                                    {foreach key=key item=item from=$backup_email}
                                    <tr>
                                        <td><INPUT type="checkbox" {$item.disable} name="{$key}" id="{$key}" value="{$key}" onClick="VerificarCheck(this, 'backup_email');" {$item.check}> <span {if !empty($item.disable)}style="text-decoration: line-through"{/if}>{$item.desc}&nbsp;{$item.msg}</span></td>
                                    </tr>
                                    {/foreach}
                                </tbody>
                            </table>
                        </td>
                    </tr>
                    <tr>
                    <!-- ********** A S T E R I X ************ -->
                        <td width="25%" valign='top'>
                            <table id="table_asterisk" width="99%" height="270px" border="0" cellspacing="0" cellpadding="0" class="tabForm" style='display:table;'>
                                <tbody>
                                    <tr>
                                        <td><legend>{$ASTERISK}</legend></td>
                                    </tr>
                                    <tr>
                                        <td><INPUT type="checkbox" name="backup_asterisk" id="backup_asterisk" onClick="ChequearTabla(this, 'table_asterisk');"><strong> {$TODO_ASTERISK}</strong></td>
                                    </tr>
                                    {foreach key=key item=item from=$backup_asterisk}
                                    <tr>
                                        <td><INPUT type="checkbox" {$item.disable} name="{$key}" id="{$key}" value="{$key}" onClick="VerificarCheck(this, 'backup_asterisk');" {$item.check}> <span {if !empty($item.disable)}style="text-decoration: line-through"{/if}>{$item.desc}&nbsp;{$item.msg}</span></td>
                                    </tr>
                                    {/foreach}
                                </tbody>
                            </table>
                        </td>
                    <!-- ********** O T H E R S ************ -->
                        <td width="25%" valign='top'>
                            <table id="table_others" width="99%" height="270px" border="0" cellspacing="0" cellpadding="0" class="tabForm" style='display:table;'>
                                <tbody>
                                    <tr>
                                        <td><legend>{$OTROS}</legend></td>
                                    </tr>
                                    <tr>
                                        <td><INPUT type="checkbox" name="backup_others" id="backup_others" onClick="ChequearTabla(this, 'table_others');"> <strong>{$TODO_OTROS}</strong></td>
                                    </tr>
                                    {foreach key=key item=item from=$backup_otros}
                                    <tr>
                                        <td><INPUT type="checkbox" {$item.disable} name="{$key}" id="{$key}" value="{$key}" onClick="VerificarCheck(this, 'backup_others');" {$item.check}> <span {if !empty($item.disable)}style="text-decoration: line-through"{/if}>{$item.desc}&nbsp;{$item.msg}</span></td>
                                    </tr>
                                    {/foreach}
                                </tbody>
                            </table>
                        </td>
                    <!-- ********** N E W   O T H E R S ************ -->
                        <td width="25%" valign='top'>
                            <table id="table_others_new" width="99%" height="270px" border="0" cellspacing="0" cellpadding="0" class="tabForm" style='display:table;'>
                                <tbody>
                                    <tr>
                                        <td><legend>{$OTROS_NEW}</legend></td>
                                    </tr>
                                    <tr>
                                        <td><INPUT type="checkbox" name="backup_others_new" id="backup_others_new" onClick="ChequearTabla(this, 'table_others_new');"> <strong>{$TODO_OTROS_NEW}</strong></td>
                                    </tr>
                                    {foreach key=key item=item from=$backup_otros_new}
                                    <tr>
                                        <td><INPUT type="checkbox" {$item.disable} name="{$key}" id="{$key}" value="{$key}" onClick="VerificarCheck(this, 'backup_others_new');" {$item.check}> <span {if !empty($item.disable)}style="text-decoration: line-through"{/if}>{$item.desc}&nbsp;{$item.msg}</span></td>
                                    </tr>
                                    {/foreach}
                                    <tr><td>&nbsp;</td></tr>
                                    <tr><td>&nbsp;</td></tr>
                                    <tr><td>&nbsp;</td></tr>
                                </tbody>
                            </table>
                        </td>
                    </tr>
                </table>
            </td>
        </tr>
    </table>
    <INPUT type="hidden" name="option_url" id="option_url" value="{$OPTION_URL}">
    <input type='hidden' name='backup_file' value='{$BACKUP_FILE}'></td>
</form>
