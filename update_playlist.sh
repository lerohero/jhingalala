#!/bin/bash

# YouTube channels: Format "Channel Name|YouTube URL|Logo URL"
channels=(
  "Jamuna TV|https://www.youtube.com/live/yDzvLqfQhyM|https://raw.githubusercontent.com/r1d3x6/tandjtales/refs/heads/Tom-and-Jerry-Tales/jamunatv.png"
  "Somoy TV|https://www.youtube.com/live/ssieXqdIxAI|https://raw.githubusercontent.com/r1d3x6/tandjtales/refs/heads/Tom-and-Jerry-Tales/somoytv.png"
  "Channel 24|https://www.youtube.com/live/HjZ48tDFjZU|https://raw.githubusercontent.com/r1d3x6/tandjtales/refs/heads/Tom-and-Jerry-Tales/channel-24.png"
)

# Output M3U header
echo "#EXTM3U"
echo "# Playlist auto-updated: $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
echo "# GitHub Repo: https://github.com/lerohero/jhingalala"
echo ""

# Fetch streams using yt-dlp
for entry in "${channels[@]}"; do
  IFS='|' read -r name url logo <<< "$entry"
  echo "[INFO] Processing: $name" >&2

  # Extract HLS stream URL (best quality)
  stream_url=$(yt-dlp -f "best[protocol=m3u8]" -g --no-check-certificate "$url" 2>/dev/null)

  if [ -n "$stream_url" ]; then
    echo "#EXTINF:-1 tvg-id=\"$name\" tvg-logo=\"$logo\" group-title=\"YouTube\",$name"
    echo "$stream_url"
    echo ""
  else
    echo "# ERROR: Failed to fetch stream for $name" >&2
  fi
done
