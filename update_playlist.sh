#!/bin/bash

# Configuration
MAX_RETRIES=2
RETRY_DELAY=3
DEBUG=true
USER_AGENT="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
LOG_PREFIX="[IPTV Updater]"

# YouTube channels: Format "Channel Name|YouTube URL|Logo URL"
channels=(
  "Jamuna TV|https://www.youtube.com/watch?v=yDzvLqfQhyM|https://raw.githubusercontent.com/r1d3x6/tandjtales/refs/heads/Tom-and-Jerry-Tales/jamunatv.png"
  "Somoy TV|https://www.youtube.com/watch?v=ssieXqdIxAI|https://raw.githubusercontent.com/r1d3x6/tandjtales/refs/heads/Tom-and-Jerry-Tales/somoytv.png"
  "Channel 24|https://www.youtube.com/watch?v=HjZ48tDFjZU|https://raw.githubusercontent.com/r1d3x6/tandjtales/refs/heads/Tom-and-Jerry-Tales/channel-24.png"
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
    if [ "$DEBUG" = true ]; then
      echo "$LOG_PREFIX Debug: Try $((retry+1)) for URL: $url" >&2
    fi
    
    stream_url=$(yt-dlp -f "best[protocol=m3u8]" -g \
                --no-check-certificate \
                --user-agent "$USER_AGENT" \
                --referer "https://www.youtube.com/" \
                "$url" 2>/dev/null)
    
    if [ -n "$stream_url" ]; then
      if [ "$DEBUG" = true ]; then
        echo "$LOG_PREFIX Debug: Successfully fetched stream URL" >&2
      fi
      echo "$stream_url"
      return 0
    fi
    
    echo "$LOG_PREFIX Retry $((retry+1)) failed for URL: $url" >&2
    sleep $RETRY_DELAY
    ((retry++))
  done
  
  return 1
}

# Function to try alternative methods
try_alternative_fetch() {
  local url=$1
  echo "$LOG_PREFIX Trying alternative methods for: $url" >&2
  
  # Method 1: Try without protocol restriction
  local stream_url=$(yt-dlp -f "best" -g \
                   --no-check-certificate \
                   --user-agent "$USER_AGENT" \
                   "$url" 2>/dev/null)
  
  if [ -n "$stream_url" ]; then
    echo "$stream_url"
    return 0
  fi
  
  # Method 2: Try with different user agent
  stream_url=$(yt-dlp -f "best[protocol=m3u8]" -g \
              --no-check-certificate \
              --user-agent "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36" \
              "$url" 2>/dev/null)
  
  [ -n "$stream_url" ] && echo "$stream_url" && return 0
  
  return 1
}

# Process each channel
for entry in "${channels[@]}"; do
  IFS='|' read -r name url logo <<< "$entry"
  echo "$LOG_PREFIX Processing: $name" >&2

  stream_url=$(fetch_stream "$url")
  
  # If primary method fails, try alternatives
  if [ -z "$stream_url" ]; then
    stream_url=$(try_alternative_fetch "$url")
  fi

  if [ -n "$stream_url" ]; then
    # Success - output channel info
    echo "#EXTINF:-1 tvg-id=\"$name\" tvg-logo=\"$logo\" group-title=\"YouTube\",$name"
    echo "$stream_url"
    echo ""
    echo "$LOG_PREFIX Success: Added $name to playlist" >&2
  else
    # Failure - log error but continue
    echo "$LOG_PREFIX ERROR: All methods failed for $name" >&2
    # Output placeholder entry to keep channel in playlist
    echo "#EXTINF:-1 tvg-id=\"$name\" tvg-logo=\"$logo\" group-title=\"YouTube (Offline)\",$name (Currently Offline)"
    echo "https://example.com/offline.mp4"
    echo ""
  fi
done

# Validate we have at least one successful channel
if ! grep -q "EXTINF" <<< "$(cat youtube_live.m3u 2>/dev/null)"; then
  echo "$LOG_PREFIX CRITICAL: No channels were processed successfully!" >&2
  exit 1
fi

echo "$LOG_PREFIX Playlist generation completed" >&2
