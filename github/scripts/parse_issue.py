"""
Reads the ISSUE_BODY env var (set by the GitHub Action), pulls out the
YouTube URL and the start timestamp, and appends one line to queue.txt
in the form:

    URL|TIMESTAMP

queue.txt lives at the repo root so it can be fetched with a plain
raw.githubusercontent.com URL by the AHK script.
"""
import os
import re

body = os.environ.get("ISSUE_BODY", "") or ""

url_pattern = re.compile(
    r'(https?://(?:www\.)?(?:youtube\.com/watch\?v=[\w-]+|youtu\.be/[\w-]+)\S*)'
)
time_pattern = re.compile(r'\b(\d{1,2}(?::\d{2}){1,2})\b')

url_match = url_pattern.search(body)
# look for the timestamp after the URL so it doesn't accidentally grab
# something out of the URL itself
time_match = time_pattern.search(body, url_match.end() if url_match else 0)

if not url_match or not time_match:
    print("Could not find both a YouTube URL and a timestamp, skipping.")
else:
    url = url_match.group(1).rstrip(").,")
    timestamp = time_match.group(1)
    with open("queue.txt", "a", encoding="utf-8") as f:
        f.write(f"{url}|{timestamp}\n")
    print(f"Queued: {url} | {timestamp}")
