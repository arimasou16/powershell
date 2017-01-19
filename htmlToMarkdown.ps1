cd "C:\Users\system76\Documents\arimasou16"
# �A�J�E���g���̐ݒ�
$username = "arimasou16"
# �ϊ�����markdown���i�[����t�H���_�̍쐬
if (Test-Path .\markdown) {
    Remove-Item .\markdown -Recurse -Force
}
New-Item ".\markdown" -itemType Directory -Force
# �ꎞ�t�@�C�����i�[����t�H���_�̍쐬
if (Test-Path .\tmp) {
    Remove-Item .\tmp -Recurse -Force
}
New-Item ".\tmp" -itemType Directory -Force
$files = Get-ChildItem -File *.html
$index = 0
$imegeidx = 0
foreach($file in $files) {
    # �w�b�_�[���
    # �^�C�g��
    $title = (Get-Content -Encoding UTF8 $file).foreach{ if ($_ -match "(?<=data-unique-entry-title=`")(.+?)(?=`" data-unique-ameba-id=)") { $matches[1] }}
    # �J�e�S���[
    $category = (Get-Content -Encoding UTF8 $file).foreach{ if ($_ -match "(?<=`" rel=`"tag`">)(.+?)(?=<\/a><\/span>)") { $matches[1] }}
    # �L���̓��t
    $date = (Get-Content -Encoding UTF8 $file).foreach{ if ($_ -match "(?<=pubdate=`"pubdate`">)(\d{4})-(\d{2})-(\d{2}) (\d{2}:\d{2})(:\d{2})(?=<\/time><\/span>)") { $matches[1] + "-" + $matches[2] + "-" + $matches[3] + " " + $matches[4] }}
    # �t�@�C����
    $octopressfile = $date.Substring(0, 10) + "-" + (++$index).toString("00000") + ".md"
    # �{���������o�͂���t�@�C��
    $bodyfile = ".\tmp\" + $date.Substring(0, 10) + "-" + ($index).toString("00000") + ".txt"
    # �{���t�@�C����markdown�`���ɕϊ�����t�@�C����
    $mdfile = ".\tmp\" + $date.Substring(0, 10) + "-" + ($index).toString("00000") + "_md.txt"
    $year = $date.Substring(0, 4)
    #�{�f�B���
    $content = (Get-Content -Encoding UTF8 $file) -as [String[]]
    $isBody = $false
    $body = ""
    foreach ($line in $content) {
        # �{���I��������
        if ($line -match "^<!--entryBottom-->$") {
            $isBody = $false
            # �{���̍ŏI�s�ɂ���</div>�A�����āA��̋�s���폜
            $body = $body.Remove($body.Length -7, 7)
        }
        if ($isBody) {
            # �󔒍s�łȂ����
            if (-not ($line -match "^\s*$")) {
                $regex = [regex]("(?<=src=`")(http://stat.ameba.jp/user_images/\d{8}/\d{2}/\w+/\w{2}/\w{2}/\w/)(\w{9}_)(\w{19}\.(jpg|png|gif))(?!.*class=`"articleImage`")")
                # �I���W�i���摜��url���쐬
                $urls = (Get-Content -Encoding UTF8 $file).foreach{ $regex.Matches($_) | ForEach { $_.Groups[1].Value + "o" + $_.Groups[3].Value }}
                foreach($url in $urls) {
                    $imagefilename = $date.Substring(0, 10) + "-" + (++$imegeidx).toString("00000") + $url.Substring($url.Length -4, 4)
                    $line = $line -replace "(?<=src=`")(http://stat.ameba.jp/user_images/\d{8}/\d{2}/\w+/\w{2}/\w{2}/\w/)(\w{9}_)(\w{19}\.(jpg|png|gif))(\??[^`"]*)(?!.*class=`"articleImage`")", ("/images/$year/" + $imagefilename)
                    $line = $line -replace "(id=`"\w{12}`" class=`"detailOn`" href=`")(http://ameblo.jp/$username/image-\d{11}-\d{11}\.html)(\??[^`"]*)", ("href=`"/images/$year/" + $imagefilename)
                }
                $regex = [regex]("(?<=src=`")(http://stat.ameba.jp/user_images/\d{8}/\d{2}/\w+/\w{2}/\w{2}/\w/o\w{19}\.(jpg|png|gif))")
                # �k������Ă��Ȃ��摜��url���쐬
                $urls = (Get-Content -Encoding UTF8 $file).foreach{ $regex.Matches($_) | ForEach { $_.Groups[1].Value }}
                foreach($url in $urls) {
                    $imagefilename = $date.Substring(0, 10) + "-" + (++$imegeidx).toString("00000") + $url.Substring($url.Length -4, 4)
                    $line = $line -replace "(?<=src=`")(http://stat.ameba.jp/user_images/\d{8}/\d{2}/\w+/\w{2}/\w{2}/\w/o\w{19}\.(jpg|png|gif))(\??[^`"]*)", ("/images/$year/" + $imagefilename)
                    $line = $line -replace "(id=`"\w{12}`" class=`"detailOn`" href=`")(http://ameblo.jp/$username/image-\d{11}-\d{11}\.html)(\??[^`"]*)", ("href=`"/images/$year/" + $imagefilename)
                }
                # �摜�̑傫���w����폜
                $line = $line -replace "height=`"[0-9]{1,4}`""
                $line = $line -replace "width=`"[0-9]{1,4}`""
                $body += $line + "`n"
            }
        }
        # �{���J�n������
        if ($line -match "^<div class=`"articleText`">$") {
            $isBody = $true
        }
    }
    echo $body | Set-Content $bodyfile -Encoding UTF8
    # pandoc���g���Ă�markdown�ϊ�
    & pandoc.exe -f html -t markdown $bodyfile -o $mdfile
    # �e�L�X�g��������(PowerShell�͕����R�[�hUTF-16���f�t�H���g�Ȃ̂�)
    $enc = New-Object System.Text.UTF8Encoding($False)
    try{
        # markdown�`��utf8�Ƃ��čŏI�I�ɏo�͂���t�@�C����
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
            # �ϊ�
            $bodyLine = $bodyLine -replace "(</?div[^>]*>)|\{style[^}]*\}|{#\w{13}}|{#\w{12}|\.detailOn}|\\`$"
            $bodyLine = $bodyLine -replace "&gt;", ">"
            $bodyLine = $bodyLine -replace "&lt;", "<"
            $bodyLine = $bodyLine + "`n"
            $lineNo++
            $charCnt += $bodyLine.Length
            if (($lineNo -ge 2) -and ($charCnt -ge 80) -and (!$add) -and ($bodyLine -match "^\s+$")) {
                # ������}��
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
