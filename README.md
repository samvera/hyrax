# Curation Concern
[![Build Status](https://travis-ci.org/pulibrary/hydra-curation_concerns.png)](https://travis-ci.org/pulibrary/hydra-curation_concerns)
[![Coverage Status](https://coveralls.io/repos/pulibrary/hydra-curation_concerns/badge.svg?branch=master)](https://coveralls.io/r/pulibrary/hydra-curation_concerns?branch=master)

A very simple extensible IR platform for Hydra

## Installation

Add this line to your application's Gemfile:

    gem 'worthwhile'

And then execute:

    $ bundle

Then:

    $ rails generate worthwhile:install
    $ rake db:migrate

## Testing

    $ rake jetty:clean
    $ rake engine_cart:generate
    $ rake spec

