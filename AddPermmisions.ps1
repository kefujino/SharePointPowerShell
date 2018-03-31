#------------
#要件
#SharePoint グループ(サイトのメンバ、サイトの所有者、サイトの閲覧者)の権限を取得
#SharePoint グループに参加しているユーザーおよびグループ名を取得
#ユーザーおよびグループのプロファイルに表示される"アカウント名"と"名前"を取得 **AllUsers の LoginName とName から取得
#-------------

#コマンド引数を設定
param(
	[Parameter(Mandatory=$True)]
	[string]$siteUrl,

	[Parameter(Mandatory=$True)]
	[string]$csvFilePath,
    
    [Parameter(Mandatory=$True)]SP
	[string]$csvFilePath2
)

#参照アセンブリのロード
[Reflection.Assembly]::LoadWithPartialName("Microsoft.SharePoint")

#サイトグループの権限テーブルのヘッダ用
Add-Content -Path $csvFilePath -Value "サイトURL,サイト名,ユーザー/グループ,権限";
Add-Content -Path $csvFilePath2 -Value "サイトURL,サイト名,グループ名,表示名,アカウント名";

#存在しないサイトURLが指定された場合の処理
if($siteUrl -eq $null) {
    Add-Content $csvFilePath "サイト URL が指定されていません。";
    return;
}


$site = New-Object Microsoft.SharePoint.SPSite($siteUrl);
$webs = $site.AllWebs;
$site.Dispose();

#権限取得対象のSharePointグループ格納用のArrryListを作成します
$associatedGroupNames = New-Object System.Collections.ArrayList;	

foreach ($web in $webs)
{
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

        #対象のグループ、またはユーザーが権限取得対象でない場合、処理を中止し、繰り返しを抜けます
        if (!$associatedGroupNames.Contains($member.Name))
        {
            #対象のSharePointグループのみ取得できているかをチェック
            #Write-Debug "$($member.Name) は、権限取得対象のグループではありません";	
            continue;
        }
        #テキストファイルにサイトURL、サイト名、グループ名を書き出します
        $stb = New-Object System.Text.StringBuilder;
        $stb.AppendFormat("{0},{1},{2}", $web.Url, $web.Title, $member.Name);
        #権限取得対象のグループが持つ権限をを取得します
        foreach ($rd in $ra.RoleDefinitionBindings)
        {
            [Void]$stb.Append($rd.Name + "/");
        }
        #末尾の "/" を削除し、取得した権限をテキストファイルに書き出します
        [Void]$stb.Remove($stb.Length -1, 1);		
        Add-Content -Path $csvFilePath -Value $stb.ToString();
        
        #対象のサイトからグループを取得
        $groups = $web.Groups;
        
        foreach($group in $groups)
        {
            #対象のグループが取得対象のグループに含まれているかを判定
            if (!$associatedGroupNames.Contains($group.Name))
            {
                #対象のSharePointグループのみ取得できているかをチェック
                Write-Debug "$($group.Name) は、権限取得対象のグループではありません";	
                continue;
            }
            #対象のグループが取得対象のグループに含まれている場合、グループが持つユーザーをすべて取得
            $groupUsers = $group.Users;
                        
            #各ユーザーのグループ名、表示名、アカウント名を取得する
            foreach($user in $groupUsers)
            {
                $stb2 = New-Object System.Text.StringBuilder;
                $stb2.AppendFormat("{0},{1},{2},{3},{4}", $web.Url, $web.Title, $group.Name, $user.Name, $user.LoginName);
                Add-Content -Path $csvFilePath2 -Value $stb2.ToString();
            }
        }
    }
    $web.Dispose();
}
