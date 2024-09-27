#!/bin/bash

# Check if the user provided a URL
if [ -z "$1" ]; then
    echo "Usage: $0 <youtube_url>"
    exit 1
fi

# Variables
URL=$1
AUDIO_FORMAT="mp3"
OUTPUT_FILE="%(title)s.%(ext)s"
THUMBNAIL_FILE="thumbnail"

# Download the best audio quality and convert it to mp3
yt-dlp -x --audio-format $AUDIO_FORMAT --audio-quality 0 -o "$OUTPUT_FILE" "$URL"

# Download the thumbnail image
yt-dlp --skip-download --write-thumbnail --convert-thumbnails jpg -o "$THUMBNAIL_FILE" "$URL"

# Extract the filename without extension
BASENAME=$(yt-dlp --get-filename -o "%(title)s" "$URL")

# Embed the thumbnail into the mp3 file using ffmpeg
ffmpeg -i "${BASENAME}.mp3" -i "$THUMBNAIL_FILE".jpg -map 0:0 -map 1:0 -c copy -id3v2_version 3 -metadata:s:v title="Album cover" -metadata:s:v comment="Cover (front)" "${BASENAME}_with_thumbnail.mp3"

# Clean up
rm "$THUMBNAIL_FILE".jpg
rm "${BASENAME}.mp3"

echo "Download and embedding of thumbnail complete."
