# Streaming websites from dockerized browser

Based on this example: https://github.com/aws-samples/amazon-chime-sdk-recording-demo

Description: https://medium.com/@afrimadonidinata/setup-online-meeting-recording-with-aws-chime-sdk-60c6e1f360c4

## How it works

 1. Launches Xvfb–virtual display
 2. Launches PulseAudio–audio server
 3. Launches Firefox and points it into some website (specified by `MEETING_URL` environment variable)
 4. Launches FFMpeg which captures video from virtual display and sound from virtual sink and streams it into RTMP endpoint (specified by `RTMP_URL` environment variable)

## Building

```sh
docker build . -t webrtc-streamer
```

## Running

```sh
docker run -it --rm \
  --env "MEETING_URL=https://v3demo.mediasoup.org/?roomId=vviqj99m" \
  --env "RTMP_URL=rtmp://user:pass@host.docker.internal:1935/live/testStream" \
  -v $(pwd):/home/user/app \
  -p 5900:5900 \
  webrtc-streamer
```

## Debugging

Watch virtual framebuffer contents with VNC:

```sh
vncviewer -encodings 'copyrect tight zrle hextile' 127.0.0.1:5900
```

In Firefox you can open devtools with `Ctrl+Shift+I`, also you can open new tab with `Ctrl+T` and enter `about:webrtc` in it.
