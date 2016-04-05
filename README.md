# CurationConcerns

[![Version](https://badge.fury.io/rb/curation_concerns.png)](http://badge.fury.io/rb/curation_concerns)
[![Build Status](https://travis-ci.org/projecthydra-labs/curation_concerns.svg?branch=master)](https://travis-ci.org/projecthydra-labs/curation_concerns)
[![Coverage Status](https://coveralls.io/repos/projecthydra-labs/curation_concerns/badge.svg?branch=master)](https://coveralls.io/r/projecthydra-labs/curation_concerns?branch=master)
[![Code Climate](https://codeclimate.com/github/projecthydra-labs/curation_concerns/badges/gpa.svg)](https://codeclimate.com/github/projecthydra-labs/curation_concerns)
[![Apache 2.0 License](http://img.shields.io/badge/APACHE2-license-blue.svg)](./LICENSE.txt)
[![Contribution Guidelines](http://img.shields.io/badge/CONTRIBUTING-Guidelines-blue.svg)](./CONTRIBUTING.md)
[![API Docs](http://img.shields.io/badge/API-docs-blue.svg)](http://rubydoc.info/gems/curation_concerns)
[![Stories in Ready](https://badge.waffle.io/projecthydra-labs/sufia-core.png?source=projecthydra-labs%2Fcuration_concerns&label=ready&title=Ready)](https://waffle.io/projecthydra-labs/sufia-core?source=projecthydra-labs%2Fcuration_concerns)

A Hydra-based Rails Engine that extends an application, adding the ability to Create, Read, Update and Destroy (CRUD) objects (based on [Hydra::Works](http://github.com/projecthydra-labs/hydra-works)) and providing a generator for defining object types with custom workflows, views, access controls, etc.

## Prerequisites

Curation Concerns requires the following software to work:

1. Solr
1. [Fedora Commons](http://www.fedora-commons.org/) digital repository
1. A SQL RDBMS (MySQL, PostgreSQL), though **note** that SQLite will be used by default if you're looking to get up and running quickly
1. [Redis](http://redis.io/), a key-value store
1. [ImageMagick](http://www.imagemagick.org/) with JPEG-2000 support
1. [FITS](#characterization) version 0.6.x
1. [LibreOffice](#derivatives)

## Installation

Checkout the dependencies for [curation_concerns-models](https://github.com/projecthydra-labs/curation_concerns/tree/master/curation_concerns-models#dependencies), which is installed as part of curation_concerns.

Add this line to your application's Gemfile:

    gem 'curation_concerns'

And then execute:

    $ bundle install

Then run the install generator.  You will be prompted if you want to overwrite the default `app/controllers/catalog_controller.rb`, to which you should type `Y` (yes). If you don't want to be prompted on overwrite, you may run the generator with the `-f` (force) option.

    $ rails generate curation_concerns:install
    $ rake db:migrate

### FITS 0.6.2

To install FITS:
 * Go to http://projects.iq.harvard.edu/fits/downloads, download __fits-0.6.2.zip__, and unpack it somewhere on your machine. You can also install FITS on OSX with homebrew: `brew install fits` (you may also have to create a symlink from fits.sh -> fits in the next step).
 * Mark fits.sh as executable (chmod a+x fits.sh)
 * Run "fits.sh -h" from the command line and see a help message to ensure FITS is properly installed
 * Give your app access to FITS by:
     * Adding the full fits.sh path to your PATH (e.g., in your .bash_profile), OR
     * Changing config/initializers/sufia.rb to point to your FITS location: config.fits_path = "/<your full path>/fits.sh"

### Redis 2.6

The redlock gem requires Redis >= 2.6.

## Usage

### Generator

To generate a new object type, use the `curation_concerns:work` Rails generator.  Follow the usage instructions provided on the command line when you run:

    $ rails generate curation_concerns:work

### Virus Detection

To turn on virus detection, install clamav on your system and add the `clamav` gem to your Gemfile

    gem 'clamav'

## Testing

If you are modifying the curation_concerns gem and want to run the test suite, follow these steps to set up the test environment.

    $ rake ci
    
Or you can do all the steps manually:

    $ solr_wrapper -p 8985 -d solr/config/ --collection_name hydra-test
    
    # in another window
    $ fcrepo_wrapper -p 8986 --no-jms
    
    # in another window
    $ rake engine_cart:generate
    $ rake curation_concerns:spec

## Help

If you have questions or need help, please email [the Hydra community tech list](mailto:hydra-tech@googlegroups.com) or stop by [the Hydra community IRC channel](irc://irc.freenode.net/projecthydra).
