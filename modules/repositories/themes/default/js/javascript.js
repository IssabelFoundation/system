function defaultValues()
{
    var chk_repos = $('input[type=checkbox][name^="repo-"]');
    chk_repos.prop('checked', false);
    chk_repos.filter('.defaultactive').prop('checked', true);;
}