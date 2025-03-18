#!/bin/bash

# Function to display help
show_help() {
    echo "Usage: $0 <youtube_url> [start_time] [end_time] [--no-thumbnail]"
    echo ""
    echo "Downloads the highest quality audio from a YouTube video and saves it as an MP3 file."
    echo "Optionally, you can specify a start time and/or an end time to extract only part of the audio."
    echo "By default, the thumbnail is embedded in the MP3 file unless --no-thumbnail is specified."
    echo ""
    echo "Arguments:"
    echo "  youtube_url    The URL of the YouTube video."
    echo "  start_time     (Optional) Start time in HH:MM:SS or seconds format."
    echo "  end_time       (Optional) End time in HH:MM:SS or seconds format."
    echo "  --no-thumbnail (Optional) Skip downloading and embedding the thumbnail."
    echo ""
    echo "Examples:"
    echo "  $0 'https://www.youtube.com/watch?v=example'               # Full audio download with thumbnail"
    echo "  $0 'https://www.youtube.com/watch?v=example' 00:02:30      # Start at 2m30s"
    echo "  $0 'https://www.youtube.com/watch?v=example' 00:02:30 00:05:00  # From 2m30s to 5m"
    echo "  $0 'https://www.youtube.com/watch?v=example' --no-thumbnail # Skip thumbnail embedding"
    echo ""
    exit 0
}

# Check if the user provided -h or --help
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    show_help
fi

# Check if a URL was provided
if [ -z "$1" ]; then
    echo "Error: No YouTube URL provided."
    show_help
fi

# Variables
URL=$1
START_TIME=$2  # Format: HH:MM:SS or seconds
END_TIME=$3    # Format: HH:MM:SS or seconds
NO_THUMBNAIL="false"
AUDIO_FORMAT="mp3"
OUTPUT_FILE="%(title)s.%(ext)s"
THUMBNAIL_FILE="thumbnail"

# Check for the --no-thumbnail flag
if [[ "$START_TIME" == "--no-thumbnail" ]]; then
    NO_THUMBNAIL="true"
    START_TIME=""  # Reset start time since it's actually a flag
    END_TIME=""
elif [[ "$END_TIME" == "--no-thumbnail" ]]; then
    NO_THUMBNAIL="true"
    END_TIME=""
elif [[ "$4" == "--no-thumbnail" ]]; then
    NO_THUMBNAIL="true"
fi

# Construct the section argument if start and/or end times are provided
SECTION_ARG=""
if [ -n "$START_TIME" ] && [ -n "$END_TIME" ]; then
    SECTION_ARG="*${START_TIME}-${END_TIME}"
elif [ -n "$START_TIME" ]; then
    SECTION_ARG="*${START_TIME}-"
elif [ -n "$END_TIME" ]; then
    SECTION_ARG="*-${END_TIME}"
fi

# Download the best audio quality and convert it to mp3, with optional trimming
if [ -n "$SECTION_ARG" ]; then
    yt-dlp -x --audio-format $AUDIO_FORMAT --audio-quality 0 --download-sections "$SECTION_ARG" -o "$OUTPUT_FILE" "$URL"
else
    yt-dlp -x --audio-format $AUDIO_FORMAT --audio-quality 0 -o "$OUTPUT_FILE" "$URL"
fi

# Extract the filename without extension
BASENAME=$(yt-dlp --get-filename -o "%(title)s" "$URL")

# Handle thumbnail embedding (skip if --no-thumbnail is provided)
if [ "$NO_THUMBNAIL" == "false" ]; then
    echo "Downloading and embedding thumbnail..."
    yt-dlp --skip-download --write-thumbnail --convert-thumbnails jpg -o "$THUMBNAIL_FILE" "$URL"
    ffmpeg -i "${BASENAME}.mp3" -i "$THUMBNAIL_FILE".jpg -map 0:0 -map 1:0 -c copy -id3v2_version 3 -metadata:s:v title="Album cover" -metadata:s:v comment="Cover (front)" "${BASENAME}_with_thumbnail.mp3"
    
    # Clean up
    rm "$THUMBNAIL_FILE".jpg
    rm "${BASENAME}.mp3"
    echo "Download and embedding of thumbnail complete."
else
    echo "Skipping thumbnail embedding."
fi

echo "Audio download complete."
