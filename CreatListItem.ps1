#カスタムリストに列とアイテムを追加するスクリプト
#大量のアイテムを持つリストで検証したい時に使用

#ループパラメータ
$ItemCount = 3000
$FieldsCount = 50

Write-Output "処理開始"

#サイトを取得します。
$web = Get-SPWeb "http://integlcsps2010:12271/sites/kefujinoTest/"
$list = $web.Lists["TestList"]
$fields = $list.Fields

Write-Output "列を作成しています"

#初期値を持ったテスト列を作成する
for ($i=0; $i -lt $FieldsCount; $i++){
    $fields.Add("field"+$i, [Microsoft.SharePoint.SPFieldType]::Text, $false)
    $field = $fields.GetField("field"+$i)
    $field.DefaultValue = "TestMessage"
    $field.Update()
}

Write-Output "アイテムを追加しています"

#アイテムを追加する
$items = $list.Items
for ($i=0; $i -lt $ItemCount; $i++){
    $item = $items.Add()
    $item["Title"] = "TestItem"+$i
    $item.Update()
}
Write-Output "終了しました"