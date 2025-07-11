Param(
    [int]$port = -1
)

$IncludeFile = Join-Path -Path $PSScriptRoot -ChildPath ".\Routing.ps1"
if( -not (Test-Path $IncludeFile) ){
    echo "[FAIL] $IncludeFile not found !"
    exit
}
. $IncludeFile
$routing = New-Object Routing

if($port -eq -1){
    $port = $routing.settingsJson.port
}

if($routing.PortChecker($port)){
    Write-host $('Port number ' + $port.ToString() + ' is already in use.')
    pause
}

[string]$url = 'http://+:' + $port.ToString() + '/'
#[string]$url = 'http://127.0.0.1:' + $port.ToString() + '/'
[string]$dirPath = Join-Path -Path $PSScriptRoot -ChildPath 'public'

# ポートの予約がなければ追加する。
$routing.URLReserve($url)

$listener = New-Object system.net.HttpListener
$listener.Prefixes.Add($url)

try {
    $listener.Start()
    $listener.Prefixes
    while ($true) {
        $context = $listener.GetContext()
        $request = $context.Request
        $response = $context.Response
        if($request.HttpMethod -eq 'GET'){
            $routing.MethodGet($response, $context.Request)
        }elseif($request.HttpMethod -eq 'POST'){
            # POST時には受け取った文字列をそのまま返す(エンコーディングは考慮しない)
            $reader = New-Object System.IO.StreamReader($request.InputStream)
            $text = $reader.ReadToEnd()
            $reader.Close()
            $bytes = [System.Text.Encoding]::UTF8.GetBytes($text)
            $response.ContentLength64 = $bytes.Length
            $response.OutputStream.Write($bytes, 0, $bytes.Length)
            $response.Close()
        }else{
            # PUTなどには未対応。必要に応じて上記のelseifを参考によしなにすること
            $response.StatusCode = 400 # Bad request
            $response.Close()
        }
    }
} finally {
    Write-host '*** finally ***'
    $listener.Stop()
    $listener.Dispose()
    Write-Error($_.Exception)
    pause
}

<#
【参考】
PowerShellでGETとPOST可能な簡易Webサーバを立てる
https://qiita.com/payaneco/items/b4b9ff5dd8eee43e0aaa

PowerShellでlocalhostを立ててみたらWebサーバの動きがちょっぴりわかったので紹介したい
https://qiita.com/S_Kosaka/items/04d875d9430f9a09b72d

PowershellでhttpServer的なモノを作る(1)
https://zenn.dev/urinco/articles/f910d1921ca839

PowerShellでJSON操作マスター：データ処理を劇的に簡単に
https://qiita.com/Tadataka_Takahashi/items/2f6813ff57bb24dbb8cb

.NETを使った簡易HTTPサーバーの実装
https://ivis-mynikki.blogspot.com/2011/02/nethttp.html
#>