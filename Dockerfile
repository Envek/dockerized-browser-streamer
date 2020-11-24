FROM ubuntu:20.04

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ENV DEBIAN_FRONTEND noninteractive

RUN groupadd --gid 1000 user \
  && useradd --uid 1000 --gid user --shell /bin/bash --create-home user

# Tini init
ARG TINI_VERSION=v0.19.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /tini
RUN chmod +x /tini
ENTRYPOINT ["/tini", "--"]

RUN /usr/bin/apt-get update && \
	/usr/bin/apt-get upgrade -y && \
	/usr/bin/apt-get install -y \
  curl \
  sudo \
  pulseaudio \
  xvfb \
  firefox \
  libnss3-tools \
  ffmpeg \
  xdotool \
  unzip \
  x11vnc \
  libfontconfig \
  libfreetype6 \
  xfonts-cyrillic \
  xfonts-scalable \
  fonts-liberation \
  fonts-ipafont-gothic \
  fonts-wqy-zenhei

RUN echo 'user ALL=(ALL:ALL) NOPASSWD:ALL' >> /etc/sudoers

# Bundle Firefox plugin to enable H264 codec support for WebRTC
RUN curl -s http://ciscobinary.openh264.org/openh264-linux64-2e1774ab6dc6c43debb0b5b628bdf122a391d521.zip -o /openh264-1.8.1.1.zip && \
    chmod a+r /openh264-1.8.1.1.zip

# Install chrome as an alternative (chromium is harder to install as it requires snap daemon on ubuntu)
RUN curl -sSL https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb -o chrome.deb && \
  apt-get install ./chrome.deb -y && \
  rm -f chrome.deb

# For debugging with VNC
EXPOSE 5900

USER user

WORKDIR /home/user/app

COPY . .

CMD [ "./entrypoint.sh" ]
