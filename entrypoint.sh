#!/bin/bash

set -xeo pipefail

export SCREEN_WIDTH=${RECORDING_SCREEN_WIDTH:-'1920'}
export SCREEN_HEIGHT=${RECORDING_SCREEN_HEIGHT:-'1080'}

# Setup shutdown logic. See https://linuxconfig.org/how-to-propagate-a-signal-to-child-processes-from-a-bash-script
trap 'trap " " SIGINT; kill -SIGINT 0; wait;' SIGINT SIGTERM

# 0. Start D-Bus for PulseAudio
sudo -i bash <<-SHELL
mkdir -p /var/run/dbus
dbus-uuidgen > /var/lib/dbus/machine-id
dbus-daemon --config-file=/usr/share/dbus-1/system.conf --print-address
SHELL

# 1. Run X11 virtual framebuffer – a virtual display – so Firefox will have somewhere to draw
SCREEN_RESOLUTION=${SCREEN_WIDTH}x${SCREEN_HEIGHT}
COLOR_DEPTH=24
X_SERVER_NUM=1

Xvfb :${X_SERVER_NUM} -ac -screen 0 ${SCREEN_RESOLUTION}x${COLOR_DEPTH} 2>&1 &
export DISPLAY=:${X_SERVER_NUM}.0
sleep 0.5  # Ensure this has started before moving on

# 2. Start PulseAudio server so Firefox will have somewhere to send audio
pulseaudio --fail -D --exit-idle-time=-1
pacmd load-module module-virtual-sink sink_name=v1  # Load a virtual sink as `v1`
pacmd set-default-sink v1  # Set the `v1` as the default sink device
pacmd set-default-source v1.monitor  # Set the monitor of the v1 sink to be the default source

# 3. Firefox
./firefox.sh & # Or ./chrome.sh &
sleep 0.5  # Wait a bit for firefox to start before moving on
xdotool mousemove 1 1 click 1  # Move mouse out of the way so it doesn't trigger the "pause" overlay on the video tile

if [ -n "$RTMP_URL" ]; then
  # 4. FFmpeg to stream into some mediaserver like Wowza
  ./ffmpeg.sh &
fi

# 5. VNC for debug (you need to publish port in docker to access it)
x11vnc -display $DISPLAY -forever -nopw -noserverdpms -quiet -xkb &

# Wait for all components: xvfb, pulseaudio, firefox, and ffmpeg, fail if either of them exits with non-zero exit code.
wait -n

# Terminate other processes
jobs -p | xargs --no-run-if-empty kill
wait

exit # If we're there that means wait -n was successful (otherwise set -e would terminate whole script before that)
