#!/bin/bash

set -e

PLAYLIST="playlist.m3u"
EPG_URL=""  # Replace with your real EPG URL

# Header
echo "#EXTM3U x-tvg-url=\"$EPG_URL\"" > "$PLAYLIST"
echo "# Generated: $(date -u +'%Y-%m-%d %H:%M:%S')" >> "$PLAYLIST"
echo "" >> "$PLAYLIST"

success_count=0
fail_count=0

# Read each channel
while IFS=',' read -r name url logo; do
    echo "🔄 Processing: $name"

    is_live=$(yt-dlp --skip-download --print "%is_live%" "$url" 2>/dev/null)
    if [[ "$is_live" != "True" ]]; then
        echo "❌ ERROR: $name is not live."
        ((fail_count++))
        continue
    fi

    stream_url=$(yt-dlp -g "$url" 2>error.log)
    if [[ $? -ne 0 || -z "$stream_url" ]]; then
        echo "❌ ERROR: Failed to fetch stream URL for $name"
        cat error.log
        ((fail_count++))
        continue
    fi

    echo "#EXTINF:-1 tvg-id=\"$name\" tvg-name=\"$name\" tvg-logo=\"$logo\" group-title=\"News\",$name" >> "$PLAYLIST"
    echo "$stream_url" >> "$PLAYLIST"
    echo "✅ SUCCESS: Added $name"
    ((success_count++))

done < channels.txt

# Summary
echo ""
echo "=== ✅ Playlist Generation Summary ==="
echo "Total Channels: $((success_count + fail_count))"
echo "Successful: $success_count"
echo "Failed: $fail_count"
echo "Playlist Line Count: $(wc -l < "$PLAYLIST")"

# Skip commit if nothing succeeded
if [[ $success_count -eq 0 ]]; then
    echo "❌ No live channels found. Skipping git commit."
    exit 1
fi

# Git commit & push
echo "🔃 Committing updated playlist..."

git config --global user.email "github-actions[bot]@users.noreply.github.com"
git config --global user.name "GitHub Actions"

git add "$PLAYLIST"
git commit -m "🔄 Update IPTV Playlist with logos ($(date -u +'%Y-%m-%d %H:%M UTC'))"
git push

echo "✅ Playlist committed and pushed!"
