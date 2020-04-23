ARG RUBY_VERSION=2.6.2
FROM ruby:$RUBY_VERSION-alpine

ARG RAILS_ENV=production
ARG APP_PATH=.dassie
ARG BUNDLE_WITHOUT=development:test
ARG EXTRA_APK_PACKAGES="git sqlite-dev"

RUN apk --no-cache upgrade && \
  apk --no-cache add build-base \
  tzdata \
  nodejs \
  $EXTRA_APK_PACKAGES

RUN gem update bundler

ENV RAILS_ENV $RAILS_ENV
ENV RACK_ENV $RAILS_ENV
ENV BUNDLE_WITHOUT $BUNDLE_WITHOUT

ENV APP_HOME /app-data/samvera/$APP_PATH
RUN mkdir -p APP_HOME

ENV BUNDLE_PATH /usr/local/bundle
ENV BUNDLE_GEMFILE $APP_HOME/Gemfile
ENV BUNDLE_JOBS 4

COPY $APP_PATH $APP_HOME
WORKDIR $APP_HOME

RUN bundle install

ADD https://time.is/just /app-data/build-time

CMD ["bundle", "exec", "puma", "-v", "-b", "tcp://0.0.0.0:3000"]
