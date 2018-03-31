 Add-PSSnapin Microsoft.SharePoint.PowerShell
 
$webapp = Get-SPWebApplication -Identity http://sp/
 
foreach($site in $webapp.Sites){
  Write-Output $site.Url "に対して処理を実行"
  $flag = $false;
  foreach ($feature in $site.Features){
    if ($feature.DefinitionId -eq "10F73B29-5779-46b3-85A8-4817A6E9A6C2"){
    Write-Output "10F73B29-5779-46b3-85A8-4817A6E9A6C2 はアクティブ済み" 
    $flag = $true;
    }
  }
  if ($flag -eq $false){
    Write-Output "test"
    $site.Features.Add([System.Guid]"10F73B29-5779-46b3-85A8-4817A6E9A6C2")
  }
  #ほか機能: $site.Features.Add([System.Guid]"10F73B29-5779-46b3-85A8-4817A6E9A6C2")
  #$site.Features.Add([System.Guid]"10F73B29-5779-46b3-85A8-4817A6E9A6C2")
}  