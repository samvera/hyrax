FROM ruby:2.6.2

ARG RAILS_ENV
ARG SECRET_KEY_BASE

# Necessary for bundler to operate properly
ENV LANG C.UTF-8
ENV LC_ALL C.UTF-8
ENV BUNDLER_VERSION 2.0.1


# add nodejs and yarn dependencies for the frontend
RUN curl -sL https://deb.nodesource.com/setup_9.x | bash - && \
  curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - && \
  echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list

RUN gem install bundler

# --allow-unauthenticated needed for yarn package
RUN apt-get update && apt-get upgrade -y && \
  apt-get install --no-install-recommends -y ca-certificates nodejs yarn \
  build-essential libpq-dev unzip ghostscript vim \
  ffmpeg \
  clamav-freshclam clamav-daemon libclamav-dev \
  qt5-default libqt5webkit5-dev xvfb xauth openjdk-8-jre --fix-missing --allow-unauthenticated

RUN mkdir /data
WORKDIR /data

# Pre-install gems so we aren't reinstalling all the gems when literally any
# filesystem change happens
RUN mkdir /data/build
ADD ./build/install_gems.sh /data/build
ADD Gemfile /data

# Add the application code
ADD . /data

RUN ./build/install_gems.sh

# Generate test app
RUN bundle exec rake engine_cart:generate

RUN bundle -v
RUN which bundle
RUN gem list bundler
