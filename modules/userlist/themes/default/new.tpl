<form method="POST" action="?menu=userlist">
<table width="99%" border="0" cellspacing="0" cellpadding="0" align="center">
<tr>
  <td>
    <table width="100%" cellpadding="4" cellspacing="0" border="0">
      <tr>
        <td align="left">
	  {if $editUserExtension eq 'yes'}
          <input class="button" type="button" name="submit_apply_changes" value="{$APPLY_CHANGES}" onclick="apply_changes()">
          {elseif $mode eq 'input'}
          <button class="button" type="submit" name="submit_save_user" value="{$SAVE}"><i class='fa fa-save'></i> {$SAVE}</button>
          <input class="button" type="submit" name="cancel" value="{$CANCEL}"></td>
          {elseif $mode eq 'edit'}
          <input class="button" type="submit" name="submit_apply_changes" value="{$APPLY_CHANGES}" >
          <input class="button" type="submit" name="cancel" value="{$CANCEL}"></td>
          {elseif $userLevel1 eq 'admin'}
          <input class="button" type="submit" name="edit" value="{$EDIT}">
          <input class="button" type="submit" name="delete" value="{$DELETE}"  onClick="return confirmSubmit('{$CONFIRM_CONTINUE}')"></td>
          {else}
          <input class="button" type="submit" name="edit" value="{$EDIT}">
          {/if}
	{if $mode ne 'view'}
	  <td align="right" nowrap><span class="letra12"><span  class="required">*</span> {$REQUIRED_FIELD}</span></td>
	{/if}
     </tr>
   </table>
  </td>
</tr>
<tr>
  <td>
    <table width="100%" border="0" cellspacing="0" cellpadding="0" class="tabForm">
      <tr>
	<td width="20%">{$name.LABEL}: {if $mode ne 'view'}<span  class="required">*</span>{/if}</td>
	<td width="30%">{$name.INPUT}</td>
	<td width="25%">{$description.LABEL}:</td>
	<td width="25%">{$description.INPUT}</td>
      </tr>
      <tr>
	<td>{$password1.LABEL}: {if $mode ne 'view'}<span  class="required">*</span>{/if}</td>
	<td>{$password1.INPUT}</td>
	<td>{$password2.LABEL}: {if $mode ne 'view'}<span class="required">*</span>{/if}</td>
	<td>{$password2.INPUT}</td>
      </tr>
      <tr>
	<td>{$group.LABEL}: {if $mode ne 'view'}<span  class="required">*</span>{/if}</td>
	<td>{$group.INPUT}</td>
	<td>{$extension.LABEL}:</td>
	<td>{$extension.INPUT}</td>
      </tr>
    </table>
 <table width="100%" border="0" cellspacing="0" cellpadding="0" align="center">
  <tr class="moduleTitle">
   <td class="moduleTitle" valign="middle">{if $THEMENAME eq "elastixneo"}<span class="neo-module-name" style="background:none;"><img src="images/email.png" width="22" height="22" />&nbsp;&nbsp;{$title_webmail}</span>{else}{$title_webmail}{/if}</td>
  </tr>
 </table>
   <table width="100%" border="0" cellspacing="0" cellpadding="0" class="tabForm">
      <tr>
        <td width="20%">{$webmailuser.LABEL}: </td>
        <td width="30%">{$webmailuser.INPUT}</td>
        <td width="25%">{$webmaildomain.LABEL}: </td>
        <td width="25%">{$webmaildomain.INPUT}</td>
      </tr>
      <tr>
        <td>{$webmailpassword1.LABEL}: </td>
        <td>{$webmailpassword1.INPUT}</td>
      </tr>
    </table>
  </td>
</tr>
</table>
<input type="hidden" name="id_user" value="{$id_user}">
</form>