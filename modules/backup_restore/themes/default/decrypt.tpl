<form method="POST" enctype="multipart/form-data" id="submit_decrypt">
    <table width="99%" border="0" cellspacing="0" cellpadding="0" align="center">
                    <tr>
                        <td align="left">{$ERROR_MSG}</td>
                    </tr>
                    <tr>
                        <td align="left">
                            <input class="button" type="submit" name="dodecrypt" value="{$PROCESS}">
                            <input class="button" type="submit" name="back" value="{$BACK}">
                        </td>
                    </tr>
                    <tr>
                       <td><br></td>
                    </tr>
                    <tr>
                        <td align="left">{$PASSPHRASE}:
                        <input type="password" name="passphrase" id="passphraase"></td>
                        <input type="hidden" id="filename" name="filename" value="{$BACKUP_FILE}">
                    </tr>
                    <tr>
                        <td><hr>{$DECRYPT_HELP}</td>
                    </tr>
    </table>
</form>
