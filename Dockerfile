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
  build-essential libpq-dev libreoffice imagemagick unzip ghostscript vim \
  ffmpeg \
  clamav-freshclam clamav-daemon libclamav-dev \
  qt5-default libqt5webkit5-dev xvfb xauth openjdk-8-jre --fix-missing --allow-unauthenticated

# fetch clamav local database
# initial update of av databases
RUN mkdir -p /var/lib/clamav && \
  wget -O /var/lib/clamav/main.cvd http://database.clamav.net/main.cvd && \
  wget -O /var/lib/clamav/daily.cvd http://database.clamav.net/daily.cvd && \
  wget -O /var/lib/clamav/bytecode.cvd http://database.clamav.net/bytecode.cvd && \
  chown clamav:clamav /var/lib/clamav/*.cvd

# install FITS for file characterization
RUN mkdir -p /opt/fits && \
  curl -fSL -o /opt/fits-1.0.5.zip http://projects.iq.harvard.edu/files/fits/files/fits-1.0.5.zip && \
  cd /opt && unzip fits-1.0.5.zip && chmod +X fits-1.0.5/fits.sh

RUN mkdir /data
WORKDIR /data

# Pre-install gems so we aren't reinstalling all the gems when literally any
# filesystem change happens
# ADD Gemfile /data
# ADD Gemfile.lock /data
RUN mkdir /data/build
ADD ./build/install_gems.sh /data/build
ADD Gemfile /data
ADD Gemfile.lock /data

# Add the application code
ADD . /data

RUN ./build/install_gems.sh

# Generate test app
RUN bundle exec rake engine_cart:generate
