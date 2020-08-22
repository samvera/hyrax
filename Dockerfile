ARG RUBY_VERSION=2.7.1
FROM ruby:$RUBY_VERSION-alpine as hyrax-base

ARG DATABASE_APK_PACKAGE="postgresql-dev"
ARG EXTRA_APK_PACKAGES="git"

RUN apk --no-cache upgrade && \
  apk --no-cache add build-base \
  tzdata \
  nodejs \
  $DATABASE_APK_PACKAGE \
  $EXTRA_APK_PACKAGES

RUN gem update bundler

RUN mkdir -p /app-data/samvera/hyrax-webapp
WORKDIR /app-data/samvera/hyrax-webapp

COPY ./bin /app-data/samvera

CMD ["bundle", "exec", "puma", "-v", "-b", "tcp://0.0.0.0:3000"]


FROM hyrax-base as hyrax

ARG APP_PATH=.

ONBUILD COPY $APP_PATH/* /app-data/samvera/hyrax-webapp/
ONBUILD RUN bundle install --jobs 4


FROM hyrax-base as hyrax-engine-dev

ARG APP_PATH=.dassie

COPY $APP_PATH/* /app-data/samvera/hyrax-webapp/
COPY . /app-data/samvera/hyrax-engine

RUN bundle install --jobs 4

ADD https://time.is/just /app-data/build-time
