ARG DEBIAN_VERSION=bookworm
ARG RUBY_VERSION=3.3

FROM ruby:$RUBY_VERSION-$DEBIAN_VERSION AS hyrax-base

RUN apt-get update && \
    curl -sL "https://deb.nodesource.com/setup_20.x" | bash - && \
    apt-get install -y --no-install-recommends \
    acl \
    build-essential \
    curl \
    exiftool \
    ffmpeg \
    ghostscript \
    git \
    imagemagick \
    less \
    libgsf-1-dev \
    libimagequant-dev \
    libjemalloc2 \
    libjpeg62-turbo-dev \
    libopenjp2-7-dev \
    libopenjp2-tools \
    libpng-dev \
    libpoppler-cpp-dev \
    libpoppler-dev \
    libpoppler-glib-dev \
    libpoppler-private-dev \
    libpoppler-qt5-dev \
    libreoffice \
    libreoffice-l10n-uk \
    librsvg2-dev \
    libtiff-dev \
    libvips-dev \
    libvips-tools \
    libwebp-dev \
    libxml2-dev \
    lsof \
    mediainfo \
    netcat-openbsd \
    nodejs \
    perl \
    poppler-utils \
    postgresql-client \
    rsync \
    ruby-grpc \
    screen \
    tesseract-ocr \
    tzdata \
    vim \
    zip \
    && \
    npm install --global yarn && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    ln -s /usr/lib/*-linux-gnu/libjemalloc.so.2 /usr/lib/libjemalloc.so.2 && \
    echo "******** Packages Installed *********"

RUN wget https://imagemagick.org/archive/binaries/magick && \
    chmod a+x magick && \
    ./magick --appimage-extract && \
    mv squashfs-root/usr/etc/ImageMagick*  /etc && \
    rm -rf squashfs-root/usr/share/doc && \
    cp -rv squashfs-root/usr/*  /usr/local && \
    rm -rf magick squashfs-root && \
    magick -version

RUN setfacl -d -m o::rwx /usr/local/bundle && \
    gem update --silent --system

RUN useradd -m -u 1001 -U -s /bin/bash --home-dir /app app && \
    mkdir -p /app/samvera/hyrax-webapp && \
    chown -R app:app /app && \
    echo "export PATH=/app/samvera/hyrax-webapp/bin:${PATH}" >> /etc/bash.bashrc

USER app
WORKDIR /app/samvera/hyrax-webapp

COPY --chown=1001 ./bin/*.sh /app/samvera/
ENV PATH="/app/samvera:$PATH" \
    RAILS_ROOT="/app/samvera/hyrax-webapp" \
    RAILS_SERVE_STATIC_FILES="1" \
    LD_PRELOAD="/usr/lib/libjemalloc.so.2" \
    MALLOC_CONF="dirty_decay_ms:1000,narenas:2,background_thread:true"

ENTRYPOINT ["hyrax-entrypoint.sh"]
CMD ["bundle", "exec", "puma", "-v", "-b", "tcp://0.0.0.0:3000"]


FROM hyrax-base AS hyrax

ARG APP_PATH=.
ARG BUNDLE_WITHOUT="development test"

ONBUILD COPY --chown=1001 $APP_PATH /app/samvera/hyrax-webapp
ONBUILD RUN bundle install --jobs "$(nproc)"
ONBUILD RUN RAILS_ENV=production SECRET_KEY_BASE=`bin/rake secret` DATABASE_URL='nulldb://nulldb' bundle exec rake assets:precompile
ARG BUILD_GITSHA
ARG BUILD_TIMESTAMP
ENV BUILD_GITSHA=$BUILD_GITSHA \
    BUILD_TIMESTAMP=$BUILD_TIMESTAMP


FROM hyrax-base AS hyrax-worker-base
USER root

RUN apt update && \
    apt install -y --no-install-recommends default-jre-headless && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    mkdir -p /app/fits && \
    cd /app/fits && \
    wget https://github.com/harvard-lts/fits/releases/download/1.6.0/fits-1.6.0.zip -O fits.zip && \
    unzip fits.zip && \
    rm fits.zip tools/mediainfo/linux/libmediainfo.so.0 tools/mediainfo/linux/libzen.so.0 && \
    chmod a+x /app/fits/fits.sh && \
    sed -i 's/\(<tool.*TikaTool.*>\)/<!--\1-->/' /app/fits/xml/fits.xml
ENV PATH="${PATH}:/app/fits"

CMD ["bundle", "exec", "sidekiq"]


FROM hyrax-worker-base AS hyrax-worker

ARG APP_PATH=.
ARG BUNDLE_WITHOUT="development test"

ONBUILD COPY --chown=1001:101 $APP_PATH /app/samvera/hyrax-webapp
ONBUILD RUN bundle install --jobs "$(nproc)"
ONBUILD RUN RAILS_ENV=production SECRET_KEY_BASE=`bin/rake secret` DATABASE_URL='nulldb://nulldb' bundle exec rake assets:precompile
ARG BUILD_GITSHA
ARG BUILD_TIMESTAMP
ENV BUILD_GITSHA=$BUILD_GITSHA \
    BUILD_TIMESTAMP=$BUILD_TIMESTAMP


FROM hyrax-worker-base AS hyrax-engine-dev

USER app
ARG BUNDLE_WITHOUT=
ENV HYRAX_ENGINE_PATH=/app/samvera/hyrax-engine

COPY --chown=1001 .dassie /app/samvera/hyrax-webapp
COPY --chown=1001 .koppie /app/samvera/hyrax-koppie
COPY --chown=1001 . /app/samvera/hyrax-engine

RUN bundle -v && \
  BUNDLE_GEMFILE=Gemfile.dassie bundle install --jobs "$(nproc)" && yarn && \
  cd $HYRAX_ENGINE_PATH && bundle install --jobs "$(nproc)" && yarn && \
  yarn cache clean

ENTRYPOINT ["dev-entrypoint.sh"]
CMD ["bundle", "exec", "puma", "-v", "-b", "tcp://0.0.0.0:3000"]
ARG BUILD_GITSHA
ARG BUILD_TIMESTAMP
ENV BUILD_GITSHA=$BUILD_GITSHA \
    BUILD_TIMESTAMP=$BUILD_TIMESTAMP
