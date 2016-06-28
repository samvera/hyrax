# CurationConcerns

Code: [![Version](https://badge.fury.io/rb/curation_concerns.png)](http://badge.fury.io/rb/curation_concerns)
[![Build Status](https://travis-ci.org/projecthydra/curation_concerns.svg?branch=master)](https://travis-ci.org/projecthydra/curation_concerns)
[![Coverage Status](https://coveralls.io/repos/projecthydra/curation_concerns/badge.svg?branch=master)](https://coveralls.io/r/projecthydra/curation_concerns?branch=master)
[![Code Climate](https://codeclimate.com/github/projecthydra/curation_concerns/badges/gpa.svg)](https://codeclimate.com/github/projecthydra/curation_concerns)

Docs: [![Apache 2.0 License](http://img.shields.io/badge/APACHE2-license-blue.svg)](./LICENSE.txt)
[![Contribution Guidelines](http://img.shields.io/badge/CONTRIBUTING-Guidelines-blue.svg)](./CONTRIBUTING.md)
[![API Docs](http://img.shields.io/badge/API-docs-blue.svg)](http://rubydoc.info/gems/curation_concerns)

Join in: [![Slack Status](http://slack.projecthydra.org/badge.svg)](http://slack.projecthydra.org/) [![Ready](https://badge.waffle.io/projecthydra/curation_concerns.svg?label=ready&title=Ready)](http://waffle.io/projecthydra/curation_concerns)


A Hydra-based Rails Engine that extends an application, adding the ability to Create, Read, Update and Destroy (CRUD) objects (based on [Hydra::Works](http://github.com/projecthydra/hydra-works)) and providing a generator for defining object types with custom workflows, views, access controls, etc.

## Prerequisites

Curation Concerns requires the following software to work:

1. Solr
1. [Fedora Commons](http://www.fedora-commons.org/) digital repository
1. A SQL RDBMS (MySQL, PostgreSQL), though **note** that SQLite will be used by default if you're looking to get up and running quickly.
1. [Redis](http://redis.io/), a key-value store. The `redlock` gem requires Redis >= 2.6.
1. [ImageMagick](http://www.imagemagick.org/) with JPEG-2000 support.
1. [LibreOffice](https://www.libreoffice.org/download/libreoffice-fresh/)
1. [FITS](#fits) version 0.8.5.
1. [FFMPEG](#ffmpeg)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'curation_concerns'
```

Then execute:

```bash
bundle install
```

Then run the install generator.  You will be prompted if you want to overwrite the default `app/controllers/catalog_controller.rb`, to which you should type `Y` (yes). If you don't want to be prompted on overwrite, you may run the generator with the `-f` (force) option.

```bash
rails generate curation_concerns:install
rake db:migrate
```

### FITS

To install FITS 0.8.5:
 * Download [fits-0.8.5.zip](http://projects.iq.harvard.edu/files/fits/files/fits-0.8.5.zip) or possibly newer from the [project page](http://projects.iq.harvard.edu/fits/downloads). Unpack it somewhere on your machine. Alternatively, use homebrew on OSX: `brew install fits` (you may also have to create a symlink from fits.sh -> fits in the next step).
 * Mark fits.sh as executable (`chmod a+x fits.sh`)
 * Run `fits.sh -h` from the command line and see a help message to ensure FITS is properly installed
 * Give your app access to FITS by:
     * Adding the full **fits.sh** path to your PATH (e.g., in your **.bash_profile**), OR
     * Changing **config/initializers/sufia.rb** to point to your FITS location: `config.fits_path = "/<your full path>/fits.sh"`

## FFMPEG

Curation Concerns includes support for transcoding audio and video files with ffmpeg > 1.0 installed.

On OSX, you can use homebrew:

```bash
brew install ffmpeg --with-fdk-aac --with-libvpx --with-libvorbis
```

Otherwise, to compile ffmpeg yourself, see the [CompilationGuide](https://trac.ffmpeg.org/wiki/CompilationGuide).

## Usage

### Generator

To generate a new object type, use the `curation_concerns:work` Rails generator.  Follow the usage instructions provided on the command line when you run:

```bash
rails generate curation_concerns:work
```

### Virus Detection

To turn on virus detection, install clamav on your system and add the `clamav` gem to your Gemfile:

```ruby
gem 'clamav'
```

## Testing

If you are modifying the curation_concerns gem and want to run the test suite, follow these steps to set up the test environment.

```bash
rake ci
```

Or you can do all the steps manually:

```bash
solr_wrapper -p 8985 -d solr/config/ --collection_name hydra-test

# in another window
fcrepo_wrapper -p 8986 --no-jms

# in another window
rake engine_cart:generate
rake curation_concerns:spec
```

## Help

If you have questions or need help, please email the [Hydra community tech list](mailto:hydra-tech@googlegroups.com) or stop by the [Hydra community IRC channel](irc://irc.freenode.net/projecthydra).
