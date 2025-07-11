class Routing{
    $ContentTypeList = @{
        '.jpg' = 'image/jpeg'
        '.png' = 'image/png'
        '.gif' = 'image/gif'
        '.mp3' = 'audio/mpeg'
        '.mp4' = 'video/mp4'
        '.m3u8' = 'application/x-mpegURL'
        '.ts' = 'video/MP2T'
        '.csv' = 'text/csv'
        '.html' = 'text/html'
        '.css' = 'text/css'
        '.ico' = 'image/vnd.microsoft.icon'
        '.js' = 'text/javascript'
        '.json' = 'application/json'
        '.pdf' = 'application/pdf'
        '.otf' = 'font/otf'
        '.ttf' = 'font/ttf'
        '.woff' = 'font/woff'
        '.woff2' = 'font/woff2'
        '.svg' = 'image/svg+xml'
        '.zip' = 'application/zip'
    }
    $settingsJson = {}
    $data = {}

    Routing(){
        chcp 65001
        $this.settingsJson = ConvertFrom-Json $(Get-Content -Path "./settings.json" -Raw)
        $this.data = ConvertFrom-Json $(Get-Content -Path "./public/data.json" -Raw)
    }

    [boolean] PortChecker([int]$port){
        $array = Get-NetTCPConnection -State Listen | Select-Object -Property LocalPort
        foreach($item in $array){
            if($($item.LocalPort -eq $port)){
                return $true
            }
        }
        return $false
    }

    [Void] URLReserve([string]$url){
        $str = $(netsh http show urlacl url="$url")
        $str = $str -join '`t'
        if($str.indexOf('Everyone') -eq -1 -or $str.indexOf('Yes') -eq -1){
            # 管理者権限で次のコマンドを実行してください。
            write-host 'Execute the following command with administrative privileges'
            write-host ('netsh http add urlacl url=' + $url + ' user=everyone')
            pause
            # $(netsh http add urlacl url="$url" user=everyone)
        }
        # 削除するには
        # netsh http delete urlacl url=http://+:58080/
    }

    [PSCustomObject] HashByQuery($query){
        $result = @{}
        if($query.Length -eq 0 -or $query.Substring(0, 1) -ne '?'){
            return $result
        }
        $query = $query.Substring(1)
        $array = $query.Split('&')
        foreach($line in $array){
            if($line.IndexOf('=') -eq -1){
                continue
            }
            $key = $line.Substring(0, $line.IndexOf('='))
            $value = $line.Substring($line.IndexOf('=') + 1)
            $result.add($key, $value)
        }
        return $result
    }

    [Void] MethodGet($response, $Request){
        $Url = $Request.Url
        # Write-host $Url.LocalPath
        Write-host ('GET ' + $Url.LocalPath)
        $queryHash = $this.HashByQuery($Url.Query)
        if($Url.LocalPath.indexOf('/~/') -eq 0){
            $filepath = $($this.settingsJson.exroot + $Url.LocalPath.substring('/~/'.Length - 1))
        }else{
            [string]$dirPath = Join-Path -Path $PSScriptRoot -ChildPath 'public'
            $filepath = Join-Path -Path $dirPath -ChildPath ($Url.LocalPath.TrimStart('/'))
        }
        #Write-host $filepath
        $response.StatusCode = 200
        $response.AddHeader('Access-Control-Allow-Origin', '*')
        if($filepath.Substring($filepath.Length - 1, 1) -eq '\'){
            $filepath += 'index.html'
        }
        if(Test-Path -Path $filepath){
            $ETag = (Get-ItemProperty $filepath).LastWriteTime.ToString().Replace(" ", "T")
            if($Request.Headers["If-None-Match"] -eq $ETag){
                $response.StatusCode = 304
                $response.Close()
                return
            }
            $response.AddHeader('ETag', $ETag)

            # ファイルがある場合
            $extension = [System.IO.Path]::GetExtension($filepath)
            if ($extension -eq '.html' -or $extension -eq '.css' -or $extension -eq '.js' -or $extension -eq '.json')
            {
                # テキストファイルの場合
                $fileContents = Get-Content -Path $filepath -Raw -Encoding UTF8
                $buffer = [System.Text.Encoding]::UTF8.GetBytes($fileContents)
            }
            else
            {
                # バイナリファイルの場合
                $buffer = [System.IO.File]::ReadAllBytes($filepath)
            }

            $response.AddHeader('Content-Type', $this.ContentTypeList[$extension])
            if($extension -eq '.m3u8'){
                $response.AddHeader('Connection', 'keep-alive')
                $response.AddHeader('Cache-Control', 'no-store')
            }
            $response.ContentLength64 = $buffer.Length
            $response.OutputStream.Write($buffer, 0, $buffer.Length)
            $response.Close()
        }elseif($Url.LocalPath -eq '/data'){
            if($queryHash.text){
                $this.data.text = $queryHash.text
            }
            $this.data.count ++
            $str = ConvertTo-Json $this.data
            $bytes = [System.Text.Encoding]::UTF8.GetBytes($str)
            $response.AddHeader('Content-Type', $this.ContentTypeList['.json'])
            $response.ContentLength64 = $bytes.Length
            $response.OutputStream.Write($bytes, 0, $bytes.Length)
            $response.Close()
            $this.data | ConvertTo-Json -Depth 4 | Out-File ".\public\data.json"
        }elseif($Url.LocalPath -eq '/data.json'){
            $this.data = ConvertFrom-Json '{"count":0, "text":"", "list":["boo","foo","woo"]}'
            $this.data | ConvertTo-Json -Depth 4 | Out-File ".\public\data.json"
            $str = ConvertTo-Json $this.data
            $bytes = [System.Text.Encoding]::UTF8.GetBytes($str)
            $response.AddHeader('Content-Type', $this.ContentTypeList['.json'])
            $response.ContentLength64 = $bytes.Length
            $response.OutputStream.Write($bytes, 0, $bytes.Length)
            $response.Close()
        }elseif($Url.LocalPath.indexOf('/.well-known/acme-challenge/') -eq 0){
            #Write-host $Url.LocalPath
            $response.AddHeader('Location', $Url.LocalPath + '/')
            $response.Close()
        }else{
            #$context.Request.Url
            $response.StatusCode = 404
            $response.Close()
        }

    }
}
<#
todo
Etagの実装

#>