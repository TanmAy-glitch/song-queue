#Requires AutoHotkey v2.0
#SingleInstance Force

; =====================================================================
;  MusicQueue.ahk
;
;  Pulls queue.txt from your GitHub repo (raw.githubusercontent.com),
;  downloads each YouTube link with yt-dlp, extracts it to mp3, trims
;  it to start at the submitted timestamp with ffmpeg, and drops it
;  into your Downloads folder as one of exactly 5 placeholders:
;      music.mp3, music1.mp3, music2.mp3, music3.mp3, music4.mp3
;
;  Requirements (all must be reachable, either on PATH or edited below):
;    - yt-dlp.exe   https://github.com/yt-dlp/yt-dlp
;    - ffmpeg.exe   https://ffmpeg.org
;    - curl.exe     ships with Windows 10/11 by default
;
;  Hotkey:
;    Ctrl+F5   ->  refresh: pull the latest queue and fill open slots
; =====================================================================

; ---------------------- CONFIG: EDIT THESE ---------------------------
RawQueueUrl := "https://raw.githubusercontent.com/YOUR_GITHUB_USERNAME/YOUR_REPO_NAME/main/queue.txt"
DownloadsDir := A_UserProfile "\Downloads"
YtDlpPath := "yt-dlp"      ; full path if it's not on PATH, e.g. "C:\tools\yt-dlp.exe"
FfmpegPath := "ffmpeg"     ; full path if it's not on PATH, e.g. "C:\tools\ffmpeg\bin\ffmpeg.exe"
; -----------------------------------------------------------------------

SlotNames := ["music", "music1", "music2", "music3", "music4"]
ProcessedFile := A_ScriptDir "\processed.txt"
QueueTempFile := A_ScriptDir "\queue_temp.txt"

TrayTip("Music Queue", "Ready. Press Ctrl+F5 to pull the queue.")

^F5:: RefreshQueue()

RefreshQueue() {
    global RawQueueUrl, DownloadsDir, YtDlpPath, FfmpegPath, SlotNames, ProcessedFile, QueueTempFile

    ; make sure Downloads exists and every following command runs from there
    if !DirExist(DownloadsDir)
        DirCreate(DownloadsDir)
    SetWorkingDir(DownloadsDir)

    ShowStatus("Pulling queue.txt ...")

    if FileExist(QueueTempFile)
        FileDelete(QueueTempFile)

    curlCmd := Format('curl.exe -s -o "{1}" "{2}"', QueueTempFile, RawQueueUrl)
    RunWait(A_ComSpec ' /c "' curlCmd '"', DownloadsDir, "Hide")

    if !FileExist(QueueTempFile) {
        ShowStatus("Could not reach the queue. Check your internet or the URL.", 4000)
        return
    }

    queueText := FileRead(QueueTempFile)
    queueLines := []
    for line in StrSplit(queueText, "`n", "`r") {
        line := Trim(line)
        if (line != "")
            queueLines.Push(line)
    }

    processedSet := Map()
    if FileExist(ProcessedFile) {
        processedText := FileRead(ProcessedFile)
        for line in StrSplit(processedText, "`n", "`r") {
            line := Trim(line)
            if (line != "")
                processedSet[line] := true
        }
    }

    newLines := []
    for line in queueLines {
        if !processedSet.Has(line) {
            newLines.Push(line)
            if (newLines.Length = 5)
                break
        }
    }

    if (newLines.Length = 0) {
        ShowStatus("No new songs in the queue.", 3000)
        return
    }

    filled := 0
    for i, line in newLines {
        parts := StrSplit(line, "|")
        if (parts.Length < 2)
            continue
        url := Trim(parts[1])
        timestamp := Trim(parts[2])
        slotName := SlotNames[i]

        ShowStatus(Format("Downloading {1} of {2}: {3}", i, newLines.Length, slotName))

        if DownloadAndTrim(url, timestamp, slotName, DownloadsDir, YtDlpPath, FfmpegPath) {
            FileAppend(line "`n", ProcessedFile)
            filled += 1
        } else {
            ShowStatus("Failed on " slotName ", skipping.", 2000)
        }
    }

    ShowStatus(Format("Done. Filled {1} slot(s) in Downloads.", filled), 4000)
}

DownloadAndTrim(url, timestamp, outName, downloadsDir, ytDlpPath, ffmpegPath) {
    tempBase := A_ScriptDir "\_dl_temp_" outName

    ; clear any leftover temp files from a previous failed run
    Loop Files, tempBase ".*"
        FileDelete(A_LoopFileFullPath)

    ytdlpCmd := Format('"{1}" -x --audio-format mp3 --audio-quality 0 --no-playlist -o "{2}.%(ext)s" "{3}"',
        ytDlpPath, tempBase, url)
    RunWait(A_ComSpec ' /c "' ytdlpCmd '"', downloadsDir, "Hide")

    tempMp3 := tempBase ".mp3"
    if !FileExist(tempMp3)
        return false

    outFile := downloadsDir "\" outName ".mp3"
    if FileExist(outFile)
        FileDelete(outFile)

    ffmpegCmd := Format('"{1}" -y -i "{2}" -ss {3} -c copy "{4}"',
        ffmpegPath, tempMp3, timestamp, outFile)
    RunWait(A_ComSpec ' /c "' ffmpegCmd '"', downloadsDir, "Hide")

    FileDelete(tempMp3)
    return FileExist(outFile) ? true : false
}

ShowStatus(msg, durationMs := 0) {
    ToolTip(msg)
    if (durationMs > 0)
        SetTimer(() => ToolTip(), -durationMs)
}
