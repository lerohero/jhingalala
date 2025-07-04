#!/bin/bash

# Configuration
MAX_RETRIES=2
RETRY_DELAY=3
LOG_PREFIX="[IPTV Updater]"

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

# Function to fetch stream with retries
fetch_stream() {
  local url=$1
  local retry=0
  local stream_url=""
  
  while [ $retry -lt $MAX_RETRIES ]; do
    stream_url=$(yt-dlp -f "best[protocol=m3u8]" -g --no-check-certificate "$url" 2>/dev/null)
    
    if [ -n "$stream_url" ]; then
      echo "$stream_url"
      return 0
    fi
    
    echo "$LOG_PREFIX Retry $((retry+1)) for URL: $url" >&2
    sleep $RETRY_DELAY
    ((retry++))
  done
  
  return 1
}

# Process each channel
for entry in "${channels[@]}"; do
  IFS='|' read -r name url logo <<< "$entry"
  echo "$LOG_PREFIX Processing: $name" >&2

  stream_url=$(fetch_stream "$url")

  if [ -n "$stream_url" ]; then
    # Success - output channel info
    echo "#EXTINF:-1 tvg-id=\"$name\" tvg-logo=\"$logo\" group-title=\"YouTube\",$name"
    echo "$stream_url"
    echo ""
    echo "$LOG_PREFIX Success: $name" >&2
  else
    # Failure - log error but continue
    echo "$LOG_PREFIX ERROR: Failed to fetch stream for $name after $MAX_RETRIES attempts" >&2
    # Optionally output a placeholder entry if you want to keep the channel in playlist
    # echo "#EXTINF:-1 tvg-id=\"$name\" tvg-logo=\"$logo\" group-title=\"YouTube (Offline)\",$name (Currently Offline)"
    # echo "https://example.com/offline.mp4"
    # echo ""
  fi
done

# Validate we have at least one successful channel
if ! grep -q "EXTINF" <<< "$(cat youtube_live.m3u)"; then
  echo "$LOG_PREFIX CRITICAL: No channels were processed successfully!" >&2
  exit 1
fi
