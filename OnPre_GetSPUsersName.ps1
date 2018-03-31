#------------
#SharePoint グループ(サイトのメンバ、サイトの所有者、サイトの閲覧者)の権限を取得
#SharePoint グループに参加しているユーザーおよびグループ名を取得
#ユーザーおよびグループのプロファイルの項目からアカウント名を取得
#-------------

#コマンド引数を設定
param(
	[Parameter(Mandatory=$True)]
	[string]$siteUrl,

	[Parameter(Mandatory=$True)]
	[string]$csvFilePath
)

<#-------------------------------
SharePoint グループと権限を取得
-------------------------------#>
function getSitePermission($web)
{
    #権限取得対象のSharePointグループ格納用のArrryListを作成します

    #サイト作成時にサイトに関連付けられるSharePoint既定のグループ名を取得します
    #変更をしていなければ、"<サイト名> の所有者" という名前がつけられる
    #親の権限を継承している場合は、"<トップサイトのサイト名> の所有者" 
    #個別の権限を設定している場合は、"<サブサイト名> の所有者"
    
    #取得対象のグループを取得 (サイトのメンバ、サイトの所有者、サイトの閲覧者))
    $associatedGroupNames.Clear();
    [Void]$associatedGroupNames.Add($web.AssociatedOwnerGroup.Name);
    [Void]$associatedGroupNames.Add($web.AssociatedMemberGroup.Name);
    [Void]$associatedGroupNames.Add($web.AssociatedVisitorGroup.Name);
    
    foreach ($ra in $web.RoleAssignments)
    {
        #SPPrincipal オブジェクトを取得
        $member = $ra.member;
        Write-Debug "$($member)";
        
        #対象のグループ、またはユーザーが権限取得対象でない場合、処理を中止し、繰り返しを抜けます
        if (!$associatedGroupNames.Contains($member.Name))
        {
            #対象のSharePointグループのみ取得できているかをチェック
            #Write-Debug "$($member.Name) は、権限取得対象のグループではありません";	
            continue;
        }
        #テキストファイルにサイトURL、サイト名、グループ名を書き出します
        $stb = New-Object System.Text.StringBuilder;
        [Void]$stb.Append($web.Url + ",");
        [Void]$stb.Append($web.Title + ",");
        [Void]$stb.Append($member.Name + ",");

        #権限取得対象のグループが持つ権限をを取得します
        foreach ($rd in $ra.RoleDefinitionBindings)
        {
            [Void]$stb.Append($rd.Name + "/");
        }
        #末尾の "/" を削除し、取得した権限をテキストファイルに書き出します
        [Void]$stb.Remove($stb.Length -1, 1);		
        Add-Content -Path $csvFilePath -Value $stb.ToString();
    }
}

<#-------------------------------
SharePoint グループと権限を取得
-------------------------------#>
function getUserProfiles($upm, $web)
{
    $allUsers = $web.AllUsers;
    #Write-Debug "$allUsers";
    foreach ($user in $allUsers)
    {
        Write-Debug "$user";
    }
}

<#----------
Main
-----------#>

#参照アセンブリのロード
[Reflection.Assembly]::LoadWithPartialName("Microsoft.SharePoint")
[Reflection.Assembly]::LoadWithPartialName("Microsoft.Office.Server")
[Reflection.Assembly]::LoadWithPartialName("Microsoft.Office.Server.UserProfiles")

#テーブルのヘッダ用
Add-Content -Path $csvFilePath -Value "サイトURL,サイト名,ユーザー/グループ,権限";

#存在しないサイトURLが指定された場合の処理
if($siteUrl -eq $null) {
    Add-Content $csvFilePath "サイト URL が指定されていません。";
    return;
}

#サイトコレクションを取得します
$site = New-Object Microsoft.SharePoint.SPSite($siteUrl);

#ユーザープロファイルを取得します
$context = [Microsoft.Office.Server.ServerContext]::GetContext($site);
$upm =  new-Object Microsoft.Office.Server.UserProfiles.UserProfileManager($context)

#サイトコレクション配下のサブサイトをすべて取得します
$webs = $site.AllWebs;
$site.Dispose();

$associatedGroupNames = New-Object System.Collections.ArrayList;	

foreach ($web in $webs)
{
    getSitePermission $web;
    getUserProfiles $upm $web;
}
