# Hydra-Head

[![Build Status](https://travis-ci.org/projecthydra/hydra-head.png?branch=master)](https://travis-ci.org/projecthydra/hydra-head)
[![Version](https://badge.fury.io/rb/active-fedora.png)](http://badge.fury.io/rb/active-fedora)
[![Dependencies](https://gemnasium.com/projecthydra/hydra-head.png)](https://gemnasium.com/projecthydra/hydra-head)
[![Coverage Status](https://img.shields.io/coveralls/projecthydra/hydra-head.svg)](https://coveralls.io/r/projecthydra/hydra-head)

Hydra-Head is a Ruby-on-Rails gem containing the core code for a web
application using the full stack of hydra building blocks.

See the github wikis for information targeted to developers:
<http://github.com/projecthydra/hydra-head/wiki>

See the duraspace hydra wikis for information at the architecture level:
<http://wiki.duraspace.org/display/hydra/>

Additionally, new adopters and potential adopters may find the pages
here useful: <http://projecthydra.org/>

If you are new to Hydra and looking to start a new Hydra head with a set
of components that have been tested for compatibility, and for which
there will be a documented upgrade path to the next versions, we
recommend you use the Hydra gem: https://github.com/projecthydra/hydra

Further questions? Ask the [hydra-tech
list](http://groups.google.com/group/hydra-tech) or join the freenode
\#projecthydra IRC channel.

## Installation/Setup

This process is covered step-by-step in the [Tutorial: Dive Into
Hydra](https://github.com/projecthydra/hydra/wiki/Dive-into-Hydra)

### Installation Prerequisites

See the [Installation Preqrequisites](http://github.com/projecthydra/hydra-head/wiki/Installation-Prerequisites) wiki page.

Ruby 1.9.3+ is required by Hydra-Head release 6+; RVM is strongly suggested.

### Install Rails

    gem install 'rails' --version '~>4.0.0'

### Generate a new rails application:

    rails new my_hydra_head
    cd my_hydra_head

### Install Dependencies

First, add them to the [Gemfile](http://gembundler.com/gemfile.html) of
your application. The new rails application you just generated will have
generated a Gemfile; add blacklight and hydra-head as below:

      source 'https://rubygems.org'

      gem 'rails'
      gem 'blacklight'
      gem 'hydra-head', '~> 10.0'

To install all of the dependencies, run:

    bundle install


### Run the generators and migrations:

Run the blacklight generator

    rails g blacklight:install --devise

Run the hydra-head generator

    rails g hydra:head -f

Run the database migrations

    rake db:migrate

### You're done.

Congratulations. You've set up the code for your Hydra Head.

Read [Tools for Developing and Testing your
Application](http://github.com/projecthydra/hydra-head/wiki/Tools-for-Developing-and-Testing-your-Application),
then read [How to Get
Started](http://github.com/projecthydra/hydra-head/wiki/How-to-Get-Started)
to get a sense of what you can do with your Hydra Head.

## Modifying and Testing the hydra-head Gem

For those developers who want to or need to work on the hydra-head gem
itself, see the [Instructions for
Contributors](http://github.com/projecthydra/hydra-head/wiki/For-Contributors)

## Acknowledgements

### Design & Strategic Contributions

The Hydra Framework would not exist without the extensive design effort undertaken by representatives of repository initiatives from Stanford University, University of Virginia, University of Hull and MediaShelf LLC.  Contributors to that effort include Tom Cramer, Lynn McRae, Martha Sites, Richard Green, Chris Awre, and Matt Zumwalt.

Thorny Staples from Fedora Commons & DuraSpace deserves special thanks for putting all of these people in the same room together.
