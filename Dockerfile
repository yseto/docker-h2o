FROM ubuntu:trusty
MAINTAINER yseto 

ENV DEBIAN_FRONTEND noninteractive
RUN locale-gen en_US.UTF-8 && dpkg-reconfigure locales
RUN apt-get update \
  && apt-get -y install git cmake libssl-dev \
    libyaml-dev libuv-dev build-essential \
    ca-certificates curl \
    pkg-config zlib1g-dev automake libtool \
    mruby libmruby-dev ruby bison \
    libgeoip-dev geoip-database libgeoip1 \
    apache2-utils \
  && rm -rf /var/lib/apt/lists/*

# go-start-server
ENV GO_START_SERVER_VERSION 0.0.2
RUN curl -L https://github.com/lestrrat/go-server-starter/releases/download/$GO_START_SERVER_VERSION/start_server_linux_amd64.tar.gz | tar zxv -C /usr/local/bin --strip=1  --wildcards '*/start_server' --no-same-owner --no-same-permissions

# libuv
ENV LIBUV_VERSION 1.7.5
RUN curl -L -O https://github.com/libuv/libuv/archive/v$LIBUV_VERSION.tar.gz \
  && tar xvfz v$LIBUV_VERSION.tar.gz \
  && rm v$LIBUV_VERSION.tar.gz \
  && cd libuv-$LIBUV_VERSION/ \
  && ./autogen.sh \
  && ./configure \
  && make \
  && make install

# h2o
ENV H2O_VERSION 1.5.0
RUN curl -L -O https://github.com/h2o/h2o/archive/v$H2O_VERSION.tar.gz \
  && tar xvfz v$H2O_VERSION.tar.gz \
  && rm v$H2O_VERSION.tar.gz

# mruby-geoip
COPY patches/ /tmp/patches/
RUN cd /h2o-$H2O_VERSION/ \
  && patch -p0 < /tmp/patches/0-geoip.patch \
  && cd /h2o-$H2O_VERSION/deps/ \
  && git clone https://github.com/matsumoto-r/mruby-geoip \
  && cd mruby-geoip/ \
  && patch -p0 < /tmp/patches/1-mruby-geoip-leak.patch \
  && rm -rf /tmp/patches/

RUN curl -L http://geolite.maxmind.com/download/geoip/database/GeoLiteCity.dat.gz | gzip -d > /usr/share/GeoIP/GeoIPCity.dat

RUN cd h2o-$H2O_VERSION/ \
  && cmake -DWITH_BUNDLED_SSL=on -DWITH_MRUBY=on . \
  && make \
  && make install

COPY h2o.conf /h2o/h2o.conf
COPY start.sh /h2o/start.sh
RUN chmod +x /h2o/start.sh
WORKDIR /h2o
ENV KILL_OLD_DELAY 1

VOLUME ["/app"]
EXPOSE 80 443
ENTRYPOINT ["/h2o/start.sh"]
CMD ["/h2o/h2o.conf"]

