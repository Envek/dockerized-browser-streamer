#!/bin/bash

set -xeuo pipefail

VIDEO_BITRATE=3000
VIDEO_FRAMERATE=30
VIDEO_GOP=$((VIDEO_FRAMERATE * 2))
AUDIO_BITRATE='192k'
AUDIO_SAMPLERATE=44100
AUDIO_CHANNELS=2

CMD=(
     ffmpeg
     -hide_banner
     -loglevel error
     # disable interaction via stdin
     -nostdin
     # screen image size
     -s ${SCREEN_WIDTH}x${SCREEN_HEIGHT}
     # video frame rate
     -r ${VIDEO_FRAMERATE}
     # hides the mouse cursor from the resulting video
     -draw_mouse 0
     # grab the x11 display as video input
     -f x11grab
         -i ${DISPLAY}
     # grab pulse as audio input
     -f pulse
         -ac 2
         -i default
     # codec video with libx264
     -c:v libx264
         -pix_fmt yuv420p
         -profile main
         -preset veryfast
         -x264opts nal-hrd=cbr:keyint=120:scenecut=0
         -minrate ${VIDEO_BITRATE}
         -maxrate ${VIDEO_BITRATE}
         -g ${VIDEO_GOP}
     # Delay audio for 1.25 seconds (value is arbitrary) to compensate constant delay of video capture
     -filter_complex "aresample=async=1000:min_hard_comp=0.100000:first_pts=0,adelay=delays=1250|1250"
     # codec audio with aac
     -c:a aac
         -b:a ${AUDIO_BITRATE}
         -ac ${AUDIO_CHANNELS}
         -ar ${AUDIO_SAMPLERATE}
         # -af "aresample=async=1:min_hard_comp=0.100000:first_pts=0"
     # adjust fragmentation to prevent seeking(resolve issue: muxer does not support non seekable output)
     -movflags frag_keyframe+empty_moov
     # set output format to RTSP
     -f rtsp
     "${RTMP_URL}"
)

exec "${CMD[@]}"
