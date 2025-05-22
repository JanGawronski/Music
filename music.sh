#!/bin/bash

git pull

download() {
    local metadata_args=""
    metadata_args="-metadata comment=\"$1\""
    if [[ -n "$2" ]]; then
        metadata_args="$metadata_args -metadata title=\"$2\""
    fi
    if [[ "$3" == "rm" ]]; then
        metadata_args="$metadata_args -metadata artist="
    elif [[ -n "$3" ]]; then
        metadata_args="$metadata_args -metadata artist=\"$3\""
    fi

    if [[ "$4" == "rm" ]]; then
        metadata_args="$metadata_args -metadata album="
    elif [[ -n "$4" ]]; then
        metadata_args="$metadata_args -metadata album=\"$4\""
    fi

    if [[ -n "$2" ]]; then
        filename="$2.%(ext)s"
    else
        filename="%(title)s.%(ext)s"
    fi

    yt-dlp \
        --extract-audio \
        --audio-quality 0 \
        --audio-format mp3 \
        --ignore-config \
        --quiet \
        --sponsorblock-remove all \
        --ppa "ThumbnailsConvertor+FFmpeg_o:-c:v mjpeg -vf crop='min(iw\,ih):min(iw\,ih)',scale=500:500:force_original_aspect_ratio=decrease,setsar=1" \
        --embed-thumbnail \
        --cookies-from-browser "firefox:~/.zen/" \
        --ppa "Metadata+FFmpeg_o:${metadata_args}" \
        --embed-metadata \
        -o "$filename" \
        -- "$1"
}

if [[ $# -ne 1 ]]; then
    echo "Usage: $0 <input_file>"
    exit 1
fi

input_file="$1"

declare -A music_meta
while IFS=$'\t' read -r id title artist album; do
    music_meta["$id"]="${title}"$'\t'"${artist}"$'\t'"${album}"
done < "$input_file"

folder_name="${input_file%.*}"

mkdir -p "$folder_name"

cd "$folder_name" || exit 1

found_ids_list=$(
    find . -name '*.mp3' |
    parallel --bar --no-run-if-empty '
        file={};
        file_id=$(ffprobe -v error -show_entries format_tags=comment -of default=noprint_wrappers=1:nokey=1 "$file");
        if [[ -z "$file_id" ]]; then
            rm "$file"
        else
            echo -e "$file\t$file_id"
        fi
    '
)

declare -A found_ids
while IFS=$'\t' read -r file file_id; do
    found_ids["$file_id"]=1
    if [[ -z "${music_meta[$file_id]}" ]]; then
        rm "$file"
    fi
done <<< "$found_ids_list"

export -f download

for id in "${!music_meta[@]}"; do
    if [[ -z "${found_ids[$id]}" ]]; then
        IFS=$'\t' read -r title artist album <<< "${music_meta[$id]}"
        printf '%s\t%s\t%s\t%s\n' "$id" "$title" "$artist" "$album"
    fi
done | parallel --bar --no-run-if-empty --colsep '\t' download '{1}' '{2}' '{3}' '{4}'