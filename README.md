# Music library synchronization tool
Uses yt-dlp and ffmpeg to synchronize music files by comparing config file and metadata of the files.

## Requirements
You need Bash, yt-dlp and ffmpeg.

## Usage
Script reads music.txt file which has the following format:
```
youtube_video_id<tab>[optional new title]<tab>[optional new artist]<tab>[optional new album]
```
To not edit the title, but e.g. artist do:
```
youtube_video_id<tab><tab>new artist
```
To remove artist or album, use `rm`:
```
youtube_video_id<tab><tab>rm<tab>rm
```