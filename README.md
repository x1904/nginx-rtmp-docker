

# Docker
## Build
    docker build -t nginx-streaming .

## Run
    docker run -p 1935:1935 -p 8080:8080  nginx-streaming



# Usage with current nginx.conf
**Warning**
Add deny and allow arguments

## RTMP/HLS/DASH
### Publish
    ffmpeg -re -i ${VIDEO}.mkv -c:a aac -ar 44100 -ac 1 -c:v libx264 -f flv 'rtmp://localhost:1935/live/${STREAM_ID}'

### Play
#### RTMP
    rtmp://localhost:1935/live/${STREAM_ID}

#### HLS: 
    http://localhost:8080/hls/${STREAM_ID}.m3u8

##### HLS Simulcast 
| Resolution     | Bandwidth |                   Link                            |
|----------------|-----------|---------------------------------------------------|
| 720p | 2628kbs | http://localhost:8080/hls/${STREAM_ID}_720p2628kbs/index.m3u8 |
| 480p | 1128kbs | http://localhost:8080/hls/${STREAM_ID}_480p1128kbs/index.m3u8 |
| 360p | 878kbs | http://localhost:8080/hls/${STREAM_ID}_360p878kbs/index.m3u8 |
| 240p | 528kbs | http://localhost:8080/hls/${STREAM_ID}_240p528kbs/index.m3u8 |
| 240p | 264kbs | http://localhost:8080/hls/${STREAM_ID}_240p264kbs/index.m3u8 |


### DASH: 
| Resolution     | Bandwidth |                   Link                            |
|----------------|-----------|---------------------------------------------------|
| 720p | 2628kbs | http://localhost:8080/dash/${STREAM_ID}_720p2628kbs/index.mpd |
| 480p | 1128kbs | http://localhost:8080/dash/${STREAM_ID}_480p1128kbs/index.mpd |
| 360p | 878kbs | http://localhost:8080/dash/${STREAM_ID}_360p878kbs/index.mpd |
| 240p | 528kbs | http://localhost:8080/dash/${STREAM_ID}_240p528kbs/index.mpd |
| 240p | 264kbs | http://localhost:8080/dash/${STREAM_ID}_240p264kbs/index.mpd |


## WEBRADIO

### Publish

The rtmp streams "mic" and "sound" are mixed and broadcasted to /webradio. Both streams must be active for ffmpeg to mix them. Otherwise, send a mixed stream directly to rtmp://localhost:1935/webradio/${STREAM_ID}.

#### Mic source
    ffmpeg -f pulse -ac 2 -i default -c:a mp3  -f flv rtmp://localhost:1935/webradio_mic/${STREAM_ID}

#### Sound source:
    ffmpeg -re -i audio.mp3 -c:a mp3 -f flv rtmp://localhost:1935/webradio_sound/${STREAM_ID}

or playlist

    while true;
    do ffmpeg -re -i "`find ~/Musique -type f -name '*.mp3'|sort -R|head -n 1`" -vn -c:a mp3 -ar 44100 -ac 2 -f flv rtmp://localhost:1935/webradio_sound/${STREAM_ID};
    done

### Play
    rtmp://localhost:1935/webradio/${STREAM_ID}