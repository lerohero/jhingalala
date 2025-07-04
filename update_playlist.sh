#!/bin/bash

# Configuration
MAX_RETRIES=2
RETRY_DELAY=5
TIMEOUT=20
user_agents=(
  "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/125.0 Safari/537.36"
  "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:127.0) Gecko/20100101 Firefox/127.0"
  "Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36 Chrome/125.0 Mobile Safari/537.36"
)
USER_AGENT="${user_agents[$RANDOM % ${#user_agents[@]}]}"

# Channel list (Name|YouTube Live URL only)
channels=(
  "Jamuna TV|https://www.youtube.com/watch?v=yDzvLqfQhyM"
  "Somoy TV|https://www.youtube.com/watch?v=ssieXqdIxAI"
  "Channel 24|https://www.youtube.com/watch?v=HjZ48tDFjZU"
)

# Output redirection support
[[ -n "$1" ]] && exec > "$1"

# Header
echo "#EXTM3U"
echo "# Updated: $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
echo ""

# Stream fetcher
fetch_stream() {
  local url="$1"
  local referer="$2"
  yt-dlp -f "best[protocol=m3u8]" -g \
    --user-agent "$USER_AGENT" \
    --referer "$referer" \
    --no-check-certificate \
    --socket-timeout "$TIMEOUT" \
    --force-ipv4 \
    --throttled-rate 100K \
    "$url" 2>/dev/null
}

# Get referer from video URL
get_referer_from_url() {
  local url="$1"
  yt-dlp --get-channel-url "$url" 2>/dev/null
}

# Process channels
for entry in "${channels[@]}"; do
  IFS='|' read -r name url <<< "$entry"
  success=false

  referer=$(get_referer_from_url "$url")
  [[ -z "$referer" ]] && referer="https://www.youtube.com/"

  for ((i=1; i<=MAX_RETRIES; i++)); do
    if stream_url=$(fetch_stream "$url" "$referer"); then
      echo "#EXTINF:-1,$name"
      echo "$stream_url"
      echo ""
      success=true
      break
    else
      echo "Attempt $i for $name failed" >&2
      sleep $RETRY_DELAY
    fi
  done

  if ! $success; then
    echo "#EXTINF:-1,$name (unavailable)"
    echo "# Could not fetch stream"
    echo ""
  fi
done
