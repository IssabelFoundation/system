<!--<form method="POST" enctype="multipart/form-data">

Comentario:  He agregado variables para que se muestre la misma vista de la 160

-->

<form method="POST" enctype="multipart/form-data">
<input type="hidden" value="" name="send" id="send">
<table width="99%" border="0" cellspacing="0" cellpadding="0" align="center">

        <tr>            
            <td width="200px"><input type="text" id="ping_hostname" name="ping_hostname" value='{$ping_hostname}' /></td>
            <td width="100px"><input type="submit" class="button" value="{php}echo _tr('Ping');{/php}" onclick="document.getElementById('send').value='ping';"></td>
            <td></td>
        </tr>
        <tr>            
            <td>&nbsp;</td>
            <td></td>
            <td></td>
        </tr>
        <tr>            
            <td width="200px"><input type="text" id="tracert_hostname" name="tracert_hostname" value='{$tracert_hostname}' /></td>
            <td width="100px"><input type="submit" class="button" value="{php}echo _tr('Trace');{/php}" onclick="document.getElementById('send').value='tracepath';"></td>
            <td></td>
        </tr>        

        <tr>            
            <td></td>
            <td></td>
            <td></td>
        </tr>
</table>
</form>
{if $frame_url neq ""}
<br><br>
<table class="tabForm" style="font-size: 16px;" cellspacing="0" cellpadding="0" width="100%">
        <tr><td align="left" colspan="2"><b>{php}echo _tr('Results');{/php}</b></td></tr>
        <tr><td align="left" colspan="2"><div class='hr-line'></div></td></tr>
    </table>
<pre style="font-family: monospace;">
<iframe name="ifm" id="ifm" frameborder=0 width="600px" height="500px" marginheight=0 marginwidth=0 scrolling=no src={$frame_url}></iframe>
</pre>
{/if}


