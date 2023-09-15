ARG NGINX_VERSION=1.24.0
ARG NGINX_RTMP_VERSION=1.2.2
ARG FFMPEG_VERSION=6.0

# NGINX-build image.
FROM alpine:latest as build-nginx
ARG NGINX_VERSION
ARG NGINX_RTMP_VERSION

RUN apk add --no-cache \
  build-base \
  ca-certificates \
  curl \
  gcc \
  libc-dev \
  libgcc \
  linux-headers \
  make \
  musl-dev \
  openssl \
  openssl-dev \
  pcre \
  pcre-dev \
  pkgconf \
  pkgconfig \
  zlib-dev

  WORKDIR /build

  RUN wget https://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz && \
  tar zxf nginx-${NGINX_VERSION}.tar.gz && \
  rm nginx-${NGINX_VERSION}.tar.gz

  RUN wget https://github.com/arut/nginx-rtmp-module/archive/v${NGINX_RTMP_VERSION}.tar.gz && \
  tar zxf v${NGINX_RTMP_VERSION}.tar.gz && \
  rm v${NGINX_RTMP_VERSION}.tar.gz

  WORKDIR /build/nginx-${NGINX_VERSION}
  RUN \
  ./configure \
  --prefix=/usr/local/nginx \
  --add-module=/build/nginx-rtmp-module-${NGINX_RTMP_VERSION} \
  --conf-path=/etc/nginx/nginx.conf \
  --with-threads \
  --with-file-aio \
  --with-http_ssl_module \
  --with-debug \
  --with-http_stub_status_module \
  --with-cc-opt="-Wimplicit-fallthrough=0" && \
  make && \
  make install

# FFmpeg-build image.
FROM alpine:latest as build-ffmpeg
ARG FFMPEG_VERSION
ARG PREFIX=/usr/local

RUN apk add --no-cache \
  build-base \
  coreutils \
  freetype-dev \
  lame-dev \
  libogg-dev \
  libass \
  libass-dev \
  libvpx-dev \
  libvorbis-dev \
  libwebp-dev \
  libtheora-dev \
  openssl-dev \
  opus-dev \
  pkgconf \
  pkgconfig \
  rtmpdump-dev \
  wget \
  x264-dev \
  x265-dev \
  yasm

RUN echo http://dl-cdn.alpinelinux.org/alpine/edge/community >> /etc/apk/repositories
RUN apk add --no-cache fdk-aac-dev

WORKDIR /build

RUN wget http://ffmpeg.org/releases/ffmpeg-${FFMPEG_VERSION}.tar.gz && \
  tar zxf ffmpeg-${FFMPEG_VERSION}.tar.gz && \
  rm ffmpeg-${FFMPEG_VERSION}.tar.gz

WORKDIR /build/ffmpeg-${FFMPEG_VERSION}
RUN \
  ./configure \
  --prefix=${PREFIX} \
  --enable-version3 \
  --enable-gpl \
  --enable-nonfree \
  --enable-small \
  --enable-libmp3lame \
  --enable-libx264 \
  --enable-libx265 \
  --enable-libvpx \
  --enable-libtheora \
  --enable-libvorbis \
  --enable-libopus \
  --enable-libfdk-aac \
  --enable-libass \
  --enable-libwebp \
  --enable-postproc \
  --enable-libfreetype \
  --enable-openssl \
  --disable-debug \
  --disable-doc \
  --disable-ffplay \
  --extra-libs="-lpthread -lm" && \
  make && \
  make install && \
  make distclean

RUN rm -rf /var/cache/* /tmp/*


# release image
FROM alpine:latest

RUN apk add --no-cache \
  ca-certificates \
  gettext \
  openssl \
  pcre \
  lame \
  libogg \
  curl \
  libass \
  libvpx \
  libvorbis \
  libwebp \
  libtheora \
  opus \
  rtmpdump \
  x264-dev \
  x265-dev

COPY --from=build-nginx /usr/local/nginx /usr/local/nginx
COPY --from=build-nginx /etc/nginx /etc/nginx
COPY --from=build-ffmpeg /usr/local /usr/local
COPY --from=build-ffmpeg /usr/lib/libx264.so /usr/lib/libx264.so
COPY --from=build-ffmpeg /usr/lib/libfdk-aac.so.2 /usr/lib/libfdk-aac.so.2
COPY --from=build-ffmpeg /usr/lib/libxcb.so.1 /usr/lib/libxcb.so.1
COPY --from=build-ffmpeg /usr/lib/libxcb-shm.so.0 /usr/lib/libxcb-shm.so.0
COPY --from=build-ffmpeg /usr/lib/libxcb-shape.so.0 /usr/lib/libxcb-shape.so.0
COPY --from=build-ffmpeg /usr/lib/libxcb-xfixes.so.0 /usr/lib/libxcb-xfixes.so.0
COPY --from=build-ffmpeg /usr/lib/libmp3lame.so.0 /usr/lib/libmp3lame.so.0
COPY --from=build-ffmpeg /usr/lib/libXau.so.6 /usr/lib/libXau.so.6
COPY --from=build-ffmpeg /usr/lib/libXdmcp.so.6 /usr/lib/libXdmcp.so.6
COPY --from=build-ffmpeg /usr/lib/libbsd.so.0 /usr/lib/libbsd.so.0
COPY --from=build-ffmpeg /usr/lib/libmd.so.0 /usr/lib/libmd.so.0
COPY nginx.conf /etc/nginx
COPY index.html /usr/local/nginx/html/index.html
COPY wrapper.sh /usr/local/bin/wrapper.sh
RUN chmod +x /usr/local/bin/wrapper.sh
# RUN mkdir -p /opt/data && mkdir /www

EXPOSE 1935
EXPOSE 443
EXPOSE 8080

CMD ["/usr/local/nginx/sbin/nginx", "-g", "daemon off;"]
