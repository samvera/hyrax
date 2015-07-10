# Curation Concern
[![Build Status](https://travis-ci.org/projecthydra-labs/curation_concerns.png)](https://travis-ci.org/projecthydra-labs/curation_concerns)
[![Coverage Status](https://coveralls.io/repos/projecthydra-labs/curation_concerns/badge.svg?branch=master)](https://coveralls.io/r/projecthydra-labs/curation_concerns?branch=master)

A Hydra-based Rails Engine that extends an application, adding the ability to Create, Read, Update and Destroy (CRUD) CurationConcern objects (a.k.a. "Works") and provides a generator for defining new CurationConcern types with custom workflow, views, access controls, etc.

## Installation

Add this line to your application's Gemfile:

    gem 'curation_concerns'

And then execute:

    $ bundle

Then:

    $ rails generate curation_concerns:install
    $ rake db:migrate

# Usage

## Generator

To generate a new CurationConcern type, use the `curation_concerns:work` rails generator.  Follow the Usage instructions provided on the command line when you run:

    rails generate curation_concerns:work

## Virus Detection

To turn on virus detection, install clamav on your system and add the `clamav` gem to your Gemfile

    gem 'clamav'

## Testing

If you are modifying the curation_concerns gem and want to run the test suite, follow these steps to set up the test environment.

```
    $ rake engine_cart:generate
    $ rake jetty:clean
    $ rake curation_concerns:jetty:config
    $ rake jetty:start
    $ rake spec
```
