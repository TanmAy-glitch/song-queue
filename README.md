# Song Queue

A tiny two-part system: a GitHub Pages site where people submit YouTube links + start
timestamps, and a local AutoHotkey script that downloads and trims them into 5 mp3
placeholders in your Downloads folder.

## How it fits together

1. Someone fills out the form on the site.
2. It opens a pre-filled GitHub **issue** (using an issue form) in a new tab. They submit it.
3. A GitHub Action (`.github/workflows/update-queue.yml`) fires on that issue, pulls the
   URL + timestamp out of it, and appends a line to `queue.txt` at the repo root:
   `https://youtu.be/xxxx|1:23`
4. The issue gets closed automatically with a thank-you comment.
5. On your machine, `ahk/MusicQueue.ahk` fetches `queue.txt`, downloads each new
   video with `yt-dlp`, trims it to start at the given timestamp with `ffmpeg`, and
   saves it as `music.mp3`, `music1.mp3`, `music2.mp3`, `music3.mp3`, `music4.mp3` in
   your Downloads folder — always exactly 5 slots.

## Setting up the repo

1. Create a new **public** GitHub repo and push everything in this folder to it.
2. In Settings → Pages, set the source to the `main` branch, root folder.
3. Open `index.html` and set `OWNER` and `REPO` near the bottom of the `<script>` tag
   to your GitHub username and repo name.
4. Open `ahk/MusicQueue.ahk` and set `RawQueueUrl` to:
   `https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/queue.txt`
5. Commit `queue.txt` (already included, empty) so the raw URL resolves from the start.

That's it — no server, no database, no API keys. The Action needs no secrets either;
`GITHUB_TOKEN` is provided automatically and the workflow's `permissions:` block
already grants it what it needs to write `queue.txt` and close issues.

## Setting up the local player

1. Install [AutoHotkey v2](https://www.autohotkey.com/).
2. Install [yt-dlp](https://github.com/yt-dlp/yt-dlp) and [ffmpeg](https://ffmpeg.org/download.html),
   and make sure both are on your PATH (or point `YtDlpPath` / `FfmpegPath` in the
   script at their full .exe paths).
3. Run `MusicQueue.ahk`.
4. Press **Ctrl+F5** any time to refresh — it pulls the newest queue entries and fills
   whichever of the 5 slots have new songs waiting.

### Notes on how the queue empties

The script keeps a local `processed.txt` next to itself, recording every queue line
it has already downloaded, so refreshing won't re-download the same song twice or
disturb slots that don't have anything new. If you want a fully clean run, just
delete `processed.txt`.

Only the first 5 *new* lines in `queue.txt` are ever pulled per refresh — that's the
hard cap on placeholders, by design.

## File map

```
index.html                                the site
queue.txt                                 the "database" (plain text, url|timestamp)
.github/ISSUE_TEMPLATE/song-request.yml   the structured issue form
.github/workflows/update-queue.yml        parses new issues into queue.txt
.github/scripts/parse_issue.py            the actual parsing logic
ahk/MusicQueue.ahk                        the local downloader/trimmer + hotkey
```
