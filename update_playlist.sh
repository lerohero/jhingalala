#!/bin/bash

# Configuration
MAX_RETRIES=2
RETRY_DELAY=5
TIMEOUT=20  # Seconds per attempt
USER_AGENT="Mozilla/5.0 (Windows NT 10.0; rv:102.0) Gecko/20100101 Firefox/102.0"

# Channel list
channels=(
  "Jamuna TV|https://www.youtube.com/watch?v=yDzvLqfQhyM"
  "Somoy TV|https://www.youtube.com/watch?v=ssieXqdIxAI"
  "Channel 24|https://www.youtube.com/watch?v=HjZ48tDFjZU"
)

# Generate M3U header
echo "#EXTM3U"
echo "# Updated: $(date -u '+%Y-%m-%d %H:%M:%S UTC')"

fetch_stream() {
  local url=$1
  yt-dlp -f "best[protocol=m3u8]" -g \
    --no-check-certificate \
    --user-agent "$USER_AGENT" \
    --referer "https://www.youtube.com/" \
    --socket-timeout "$TIMEOUT" \
    --force-ipv4 \
    --throttled-rate 100K \
    "$url" 2>/dev/null
}

# Process channels
for entry in "${channels[@]}"; do
  IFS='|' read -r name url <<< "$entry"
  
  for ((i=1; i<=MAX_RETRIES; i++)); do
    if stream_url=$(fetch_stream "$url"); then
      echo "#EXTINF:-1,$name"
      echo "$stream_url"
      echo ""
      break
    fi
    sleep $RETRY_DELAY
  done
done
