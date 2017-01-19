cd "C:\Users\system76\Documents\arimasou16"
# アカウント名の設定
$username = "arimasou16"
# 変換したmarkdownを格納するフォルダの作成
if (Test-Path .\markdown) {
    Remove-Item .\markdown -Recurse -Force
}
New-Item ".\markdown" -itemType Directory -Force
# 一時ファイルを格納するフォルダの作成
if (Test-Path .\tmp) {
    Remove-Item .\tmp -Recurse -Force
}
New-Item ".\tmp" -itemType Directory -Force
$files = Get-ChildItem -File *.html
$index = 0
$imegeidx = 0
foreach($file in $files) {
    # ヘッダー情報
    # タイトル
    $title = (Get-Content -Encoding UTF8 $file).foreach{ if ($_ -match "(?<=data-unique-entry-title=`")(.+?)(?=`" data-unique-ameba-id=)") { $matches[1] }}
    # カテゴリー
    $category = (Get-Content -Encoding UTF8 $file).foreach{ if ($_ -match "(?<=`" rel=`"tag`">)(.+?)(?=<\/a><\/span>)") { $matches[1] }}
    # 記事の日付
    $date = (Get-Content -Encoding UTF8 $file).foreach{ if ($_ -match "(?<=pubdate=`"pubdate`">)(\d{4})-(\d{2})-(\d{2}) (\d{2}:\d{2})(:\d{2})(?=<\/time><\/span>)") { $matches[1] + "-" + $matches[2] + "-" + $matches[3] + " " + $matches[4] }}
    # ファイル名
    $octopressfile = $date.Substring(0, 10) + "-" + (++$index).toString("00000") + ".md"
    # 本文だけを出力するファイル
    $bodyfile = ".\tmp\" + $date.Substring(0, 10) + "-" + ($index).toString("00000") + ".txt"
    # 本文ファイルをmarkdown形式に変換するファイル名
    $mdfile = ".\tmp\" + $date.Substring(0, 10) + "-" + ($index).toString("00000") + "_md.txt"
    $year = $date.Substring(0, 4)
    #ボディ情報
    $content = (Get-Content -Encoding UTF8 $file) -as [String[]]
    $isBody = $false
    $body = ""
    foreach ($line in $content) {
        # 本文終了か判定
        if ($line -match "^<!--entryBottom-->$") {
            $isBody = $false
            # 本文の最終行にある</div>、そして、上の空行を削除
            $body = $body.Remove($body.Length -7, 7)
        }
        if ($isBody) {
            # 空白行でなければ
            if (-not ($line -match "^\s*$")) {
                $regex = [regex]("(?<=src=`")(http://stat.ameba.jp/user_images/\d{8}/\d{2}/\w+/\w{2}/\w{2}/\w/)(\w{9}_)(\w{19}\.(jpg|png|gif))(?!.*class=`"articleImage`")")
                # オリジナル画像のurlを作成
                $urls = (Get-Content -Encoding UTF8 $file).foreach{ $regex.Matches($_) | ForEach { $_.Groups[1].Value + "o" + $_.Groups[3].Value }}
                foreach($url in $urls) {
                    $imagefilename = $date.Substring(0, 10) + "-" + (++$imegeidx).toString("00000") + $url.Substring($url.Length -4, 4)
                    $line = $line -replace "(?<=src=`")(http://stat.ameba.jp/user_images/\d{8}/\d{2}/\w+/\w{2}/\w{2}/\w/)(\w{9}_)(\w{19}\.(jpg|png|gif))(\??[^`"]*)(?!.*class=`"articleImage`")", ("/images/$year/" + $imagefilename)
                    $line = $line -replace "(id=`"\w{12}`" class=`"detailOn`" href=`")(http://ameblo.jp/$username/image-\d{11}-\d{11}\.html)(\??[^`"]*)", ("href=`"/images/$year/" + $imagefilename)
                }
                $regex = [regex]("(?<=src=`")(http://stat.ameba.jp/user_images/\d{8}/\d{2}/\w+/\w{2}/\w{2}/\w/o\w{19}\.(jpg|png|gif))")
                # 縮小されていない画像のurlを作成
                $urls = (Get-Content -Encoding UTF8 $file).foreach{ $regex.Matches($_) | ForEach { $_.Groups[1].Value }}
                foreach($url in $urls) {
                    $imagefilename = $date.Substring(0, 10) + "-" + (++$imegeidx).toString("00000") + $url.Substring($url.Length -4, 4)
                    $line = $line -replace "(?<=src=`")(http://stat.ameba.jp/user_images/\d{8}/\d{2}/\w+/\w{2}/\w{2}/\w/o\w{19}\.(jpg|png|gif))(\??[^`"]*)", ("/images/$year/" + $imagefilename)
                    $line = $line -replace "(id=`"\w{12}`" class=`"detailOn`" href=`")(http://ameblo.jp/$username/image-\d{11}-\d{11}\.html)(\??[^`"]*)", ("href=`"/images/$year/" + $imagefilename)
                }
                # 画像の大きさ指定を削除
                $line = $line -replace "height=`"[0-9]{1,4}`""
                $line = $line -replace "width=`"[0-9]{1,4}`""
                $body += $line + "`n"
            }
        }
        # 本文開始か判定
        if ($line -match "^<div class=`"articleText`">$") {
            $isBody = $true
        }
    }
    echo $body | Set-Content $bodyfile -Encoding UTF8
    # pandocを使ってのmarkdown変換
    & pandoc.exe -f html -t markdown $bodyfile -o $mdfile
    # テキスト書き込み(PowerShellは文字コードUTF-16がデフォルトなので)
    $enc = New-Object System.Text.UTF8Encoding($False)
    try{
        # markdown形式utf8として最終的に出力するファイル名
        $writefile = $file.DirectoryName + "\markdown\" + $octopressfile
        $stream_w = New-Object system.IO.Streamwriter("$writefile", $false, $enc)
        $stream_w.Write("---" + "`n")
        $stream_w.Write("layout: post" + "`n")
        $stream_w.Write("title: `"$title`"" + "`n")
        $stream_w.Write("DATE: $date" + "`n")
        $stream_w.Write("comments: true" + "`n")
        $stream_w.Write("categories: $category" + "`n")
        $stream_w.Write("tags: $category" + "`n")
        $stream_w.Write("author: $username " + "`n")
        $stream_w.Write("---" + "`n")
        $lineNo = 0
        $charCnt = 0
        $add = $false
        $content = (Get-Content -Encoding UTF8 $mdfile) -as [String[]]
        foreach ($bodyLine in $content) {
            # 変換
            $bodyLine = $bodyLine -replace "(</?div[^>]*>)|\{style[^}]*\}|{#\w{13}}|{#\w{12}|\.detailOn}|\\`$"
            $bodyLine = $bodyLine -replace "&gt;", ">"
            $bodyLine = $bodyLine -replace "&lt;", "<"
            $bodyLine = $bodyLine + "`n"
            $lineNo++
            $charCnt += $bodyLine.Length
            if (($lineNo -ge 2) -and ($charCnt -ge 80) -and (!$add) -and ($bodyLine -match "^\s+$")) {
                # 続きを挿入
                $stream_w.Write("<!-- more -->`n")
                $add = $true
            }
            $stream_w.Write($bodyLine)
        }
    } finally {
        $stream_w.close()
    }
}
Remove-Item .\tmp -Recurse -Force
