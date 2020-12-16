ARG RUBY_VERSION=2.7.1
FROM ruby:$RUBY_VERSION-alpine as hyrax-base

ARG DATABASE_APK_PACKAGE="postgresql-dev"
ARG EXTRA_APK_PACKAGES="git"

RUN apk --no-cache upgrade && \
  apk --no-cache add build-base \
  imagemagick \
  tzdata \
  nodejs \
  yarn \
  $DATABASE_APK_PACKAGE \
  $EXTRA_APK_PACKAGES

RUN addgroup -S --gid 101 app && \
  adduser -S -G app -u 1001 -s /bin/sh -h /app app
USER app

RUN gem update bundler

RUN mkdir -p /app/samvera/hyrax-webapp
WORKDIR /app/samvera/hyrax-webapp

COPY --chown=1001:101 ./bin /app/samvera
ENV PATH="/app/samvera:$PATH"
ENV RAILS_ROOT="/app/samvera/hyrax-webapp"
ENV RAILS_SERVE_STATIC_FILES="1"

ENTRYPOINT ["hyrax-entrypoint.sh"]
CMD ["bundle", "exec", "puma", "-v", "-b", "tcp://0.0.0.0:3000"]


FROM hyrax-base as hyrax

ARG APP_PATH=.
ARG BUNDLE_WITHOUT="development test"

ONBUILD COPY --chown=1001:101 $APP_PATH /app/samvera/hyrax-webapp
ONBUILD RUN bundle install --jobs "$(nproc)"
ONBUILD RUN DB_ADAPTER=nulldb DATABASE_URL='postgresql://fake' bundle exec rake assets:precompile

FROM hyrax-base as hyrax-engine-dev

ARG APP_PATH=.dassie
ARG BUNDLE_WITHOUT=

ENV HYRAX_ENGINE_PATH /app/samvera/hyrax-engine

COPY --chown=1001:101 $APP_PATH /app/samvera/hyrax-webapp
COPY --chown=1001:101 . /app/samvera/hyrax-engine

RUN cd /app/samvera/hyrax-engine; bundle install --jobs "$(nproc)"
RUN DB_ADAPTER=nulldb DATABASE_URL='postgresql://fake' bundle exec rake assets:precompile


FROM hyrax-engine-dev as hyrax-engine-dev-worker

ENV MALLOC_ARENA_MAX=2

USER root
RUN apk --no-cache add bash \
  openjdk11-jre \
  perl \
  mediainfo
USER app

RUN wget http://projects.iq.harvard.edu/files/fits/files/fits-1.0.5.zip -O fits.zip \
    && unzip fits.zip -d /app \
    && rm fits.zip \
    && mv /app/fits-1.0.5 /app/fits \
    && chmod a+x /app/fits/fits.sh
ENV PATH="${PATH}:/app/fits"

CMD bundle exec sidekiq
