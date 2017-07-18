![Logo](https://raw.githubusercontent.com/projecthydra-labs/hyrax/gh-pages/assets/images/hyrax_logo_horizontal_white_background.png)

Code: [![Version](https://badge.fury.io/rb/hyrax.png)](http://badge.fury.io/rb/hyrax)
[![Build Status](https://travis-ci.org/projecthydra-labs/hyrax.png?branch=master)](https://travis-ci.org/projecthydra-labs/hyrax)
[![Coverage Status](https://coveralls.io/repos/github/projecthydra-labs/hyrax/badge.svg?branch=master)](https://coveralls.io/github/projecthydra-labs/hyrax?branch=master)
[![Code Climate](https://codeclimate.com/github/projecthydra-labs/hyrax/badges/gpa.svg)](https://codeclimate.com/github/projecthydra-labs/hyrax)
[![Dependency Update Status](https://gemnasium.com/projecthydra-labs/hyrax.png)](https://gemnasium.com/projecthydra-labs/hyrax)
[![Dependency Maintenance Status](https://dependencyci.com/github/projecthydra-labs/hyrax/badge)](https://dependencyci.com/github/projecthydra-labs/hyrax)

Docs: [![Documentation Status](https://inch-ci.org/github/projecthydra-labs/hyrax.svg?branch=master)](https://inch-ci.org/github/projecthydra-labs/hyrax)
[![API Docs](http://img.shields.io/badge/API-docs-blue.svg)](http://rubydoc.info/gems/hyrax)
[![Contribution Guidelines](http://img.shields.io/badge/CONTRIBUTING-Guidelines-blue.svg)](./.github/CONTRIBUTING.md)
[![Apache 2.0 License](http://img.shields.io/badge/APACHE2-license-blue.svg)](./LICENSE)

Jump in: [![Slack Status](http://slack.projecthydra.org/badge.svg)](http://slack.projecthydra.org/)
[![Ready Tickets](https://badge.waffle.io/projecthydra-labs/hyrax.png?label=ready&milestone=1.0.0&title=Ready)](https://waffle.io/projecthydra-labs/hyrax?milestone=1.0.0)

# Table of Contents

  * [What is Hyrax?](#what-is-hyrax)
    * [Feature list](#feature-list)
  * [Help](#help)
  * [Getting started](#getting-started)
    * [Prerequisites](#prerequisites)
      * [Characterization](#characterization)
      * [Derivatives](#derivatives)
    * [Environments](#environments)
    * [Ruby](#ruby)
    * [Redis](#redis)
    * [Rails](#rails)
      * [JavaScript runtime](#javascript-runtime)
  * [Creating a Hyrax\-based app](#creating-a-hyrax-based-app)
    * [Generate a work type](#generate-a-work-type)
    * [Start servers](#start-servers)
    * [Start background workers](#start-background-workers)
    * [Create default administrative set](#create-default-administrative-set)
  * [Managing a Hyrax\-based app](#managing-a-hyrax-based-app)
    * [Toggling features](#toggling-features)
  * [License](#license)
  * [Contributing](#contributing)
  * [Development](#development)
  * [Release process](#release-process)
  * [Acknowledgments](#acknowledgments)

# What is Hyrax?

Hyrax is a front-end based on the robust [Hydra](http://projecthydra.org) framework, providing a user interface for common repository features. Hyrax offers the ability to create repository object types on demand, to deposit content via multiple configurable workflows, and to describe content with flexible metadata. Numerous optional features may be turned on in the administrative dashboard or added through plugins. It is implemented as a Rails engine, so it may be the base of, or added to, a Rails application. Hyrax is the consolidation of Sufia and the CurationConcerns gems and behaves in much the same way.

## Feature list

Hyrax has many features. [Read more about what they are and how to turn them on](https://github.com/projecthydra/sufia/wiki/Feature-matrix). See the [Sufia Management Guide](https://github.com/projecthydra/sufia/wiki/Sufia-Management-Guide) to learn more.

For non-technical documentation about Hyrax, see the Hyrax [documentation site](http://hyr.ax/).

# Help

If you have questions or need help, please email [the Hydra community tech list](mailto:hydra-tech@googlegroups.com) or stop by the #dev channel in [the Hydra community Slack team](https://wiki.duraspace.org/pages/viewpage.action?pageId=43910187#Getintouch!-Slack).

# Getting started

This document contains instructions specific to setting up an app with __Hyrax
v1.0.3__. If you are looking for instructions on installing a different
version, be sure to select the appropriate branch or tag from the drop-down
menu above.

Prerequisites are required for both Creating a Hyrax\-based app and Contributing new features to Hyrax.
After installing the Prerequisites:
 * If you would like to create a new application using Hyrax follow the instructions for [Creating a Hyrax\-based app](#creating-a-hyrax-based-app).
 * If you would like to create new features for Hyrax follow the instructions for [Contributing](#contributing) and [Development](#development).

## Prerequisites

Hyrax requires the following software to work:

1. [Solr](http://lucene.apache.org/solr/) version >= 5.x (tested up to 6.4.1)
1. [Fedora Commons](http://www.fedora-commons.org/) digital repository version >= 4.5.1 (tested up to 4.7.1)
1. A SQL RDBMS (MySQL, PostgreSQL), though **note** that SQLite will be used by default if you're looking to get up and running quickly
1. [Redis](http://redis.io/), a key-value store
1. [ImageMagick](http://www.imagemagick.org/) with JPEG-2000 support
1. [FITS](#characterization) version 0.8.x (0.8.5 is known to be good)
1. [LibreOffice](#derivatives)

**NOTE: The [Sufia Development Guide](https://github.com/projecthydra/sufia/wiki/Sufia-Development-Guide) has instructions for installing Solr and Fedora in a development environment.**

### Characterization

1. Go to http://projects.iq.harvard.edu/fits/downloads and download a copy of FITS (see above to pick a known working version) & unpack it somewhere on your machine.
1. Mark fits.sh as executable: `chmod a+x fits.sh`
1. Run `fits.sh -h` from the command line and see a help message to ensure FITS is properly installed
1. Give your Hyrax app access to FITS by:
    1. Adding the full fits.sh path to your PATH (e.g., in your .bash\_profile), **OR**
    1. Changing `config/initializers/hyrax.rb` to point to your FITS location:  `config.fits_path = "/<your full path>/fits.sh"`

### Derivatives

Install [LibreOffice](https://www.libreoffice.org/). If `which soffice` returns a path, you're done. Otherwise, add the full path to soffice to your PATH (in your `.bash_profile`, for instance). On OSX, soffice is **inside** LibreOffice.app. Your path may look like "/path/to/LibreOffice.app/Contents/MacOS/"

You may also require [ghostscript](http://www.ghostscript.com/) if it does not come with your compiled version LibreOffice. `brew install ghostscript` should resolve the dependency on a mac.

**NOTE**: Derivatives are served from the filesystem in Hyrax.

## Environments

Note here that the following commands assume you're setting up Hyrax in a development environment (using the Rails built-in development environment). If you're setting up a production or production-like environment, you may wish to tell Rails that by prepending `RAILS_ENV=production` to the commands that follow, e.g., `rails`, `rake`, `bundle`, and so on.

## Ruby

First, you'll need a working Ruby installation. You can install this via your operating system's package manager -- you are likely to get farther with OSX, Linux, or UNIX than Windows but your mileage may vary -- but we recommend using a Ruby version manager such as [RVM](https://rvm.io/) or [rbenv](https://github.com/sstephenson/rbenv).

We recommend either Ruby 2.3 or the latest 2.2 version.

## Redis

[Redis](http://redis.io/) is a key-value store that Hyrax uses to provide activity streams on repository objects and users, and to prevent race conditions as a global mutex when modifying order-persisting objects.

Starting up Redis will depend on your operating system, and may in fact already be started on your system. You may want to consult the [Redis documentation](http://redis.io/documentation) for help doing this.

## Rails

Hyrax requires Rails 5. We recommend the latest Rails 5.0 release.

```
# If you don't already have Rails at your disposal...
gem install rails -v 5.0.1
```

### JavaScript runtime

Rails requires that you have a JavaScript runtime -- for example, nodejs -- installed. Either install nodejs or uncomment the `rubyracer` line in your Gemfile and run `bundle install` before running Hyrax's install generator.

# Creating a Hyrax-based app

Generate a new Rails application using the template.

```
rails new my_app -m https://raw.githubusercontent.com/samvera/hyrax/v1.0.3/template.rb
```

Generating a new Rails application using Hyrax's template above takes cares of a number of steps for you, including:

* Adding Hyrax (and any of its dependencies) to your application `Gemfile`, to declare that Hyrax is a dependency of your application
* Running `bundle install`, to install Hyrax and its dependencies
* Running Hyrax's install generator, to add a number of files that Hyrax requires within your Rails app, including e.g. database migrations
* Loading all of Hyrax's database migrations into your application's database
* Loading Hyrax's default workflows into your application's database

## Generate a work type

Hyrax allows you to specify your work types by using a generator. You may generate one or more of these work types.

Pass a (CamelCased) model name to Hyrax's work generator to get started, e.g.:

```
rails generate hyrax:work Work
```

or

```
rails generate hyrax:work MovingImage
```

Namespaces can be included in the work My::MovingImage by adding the path.

```
rails generate hyrax:work My/MovingImage
```

You may wish to [customize your work type](https://github.com/projecthydra/sufia/wiki/Customizing-your-work-types) now that it's been generated.

## Start servers

To test-drive your new Hyrax application in development mode, spin up the servers that Hyrax needs (Solr, Fedora, and Rails):

```
rake hydra:server
```

And now you should be able to browse to [localhost:3000](http://localhost:3000/) and see the application. Note that this web server is purely for development purposes; you will want to use a more fully featured [web server](#web-server) for production-like environments.

## Start background workers

Many of the services performed by Hyrax are resource intensive, and therefore are well suited to running as background jobs that can be managed and executed by a message queuing system. Examples include:

* File ingest
* Derivative generation
* Characterization
* Fixity
* Solr indexing

Hyrax implements these jobs using the Rails [ActiveJob](http://edgeguides.rubyonrails.org/active_job_basics.html) framework, allowing you to choose the message queue system of your choice.

For initial testing and development, it is recommended that you change the default ActiveJob adapter from `:async` to `:inline`. This adapter will execute jobs immediately (in the foreground) as they are received. This can be accomplished by adding the following to your `config/application.rb`

```
class Application < Rails::Application
  # ...
  config.active_job.queue_adapter = :inline
  # ...
end
```

**For production applications** you will want to use a more robust message queue system such as [Sidekiq](http://sidekiq.org/) or [Resque](https://github.com/resque/resque). The Sufia Development Guide has a detailed walkthrough of [installing and configuring Resque](https://github.com/projecthydra/sufia/wiki/Background-Workers-(Resque-in-Sufia-7). Initial Sidekiq instructions for ActiveJob are available on the [Sidekiq wiki](https://github.com/mperham/sidekiq/wiki/Active-Job).

## Load workflows
Load workflows from the json files in `config/workflows` by running the following rake task:

```
rake hyrax:workflow:load
```

## Create default administrative set

**After** Fedora and Solr are running, create the default administrative set -- into which all works will be deposited unless assigned to other administrative sets -- by running the following rake task:

```
rake hyrax:default_admin_set:create
```

**NOTE**: You will want to run this command the first time this code is deployed to a new environment as well.

# Managing a Hyrax-based app

The [Sufia Management Guide](https://github.com/projecthydra/sufia/wiki/Sufia-Management-Guide) provides tips for how to manage, customize, and enhance your Hyrax application, including guidance specific to:

* Production implementations
* Configuration of background workers
* Integration with e.g., Dropbox, Google Analytics, and Zotero
* Audiovisual transcoding with `ffmpeg`
* Setting up administrative users
* Metadata customization

## Toggling Features

Some features in Hyrax can be flipped on and off from either the Administrative
Dashboard or via a YAML configuration file at `config/features.yml`. An example
of the YAML file is below:

```yaml
assign_admin_set:
  enabled: "false"
proxy_deposit:
  enabled: "false"
```

If both options exist, whichever option is set from the Administrative Dashboard
will take precedence.

# License

Hyrax is available under [the Apache 2.0 license](LICENSE.md).

# Contributing

We'd love to accept your contributions.  Please see our guide to [contributing to Hyrax](./.github/CONTRIBUTING.md).

If you'd like to help the development effort and you're not sure where to get started, you can always grab a ticket in the "Ready" column from our [Waffle board](https://waffle.io/projecthydra-labs/hyrax). There are other ways to help, too.

* [Contribute a user story](https://github.com/projecthydra-labs/hyrax/issues/new).
* Help us improve [Hyrax's test coverage](https://coveralls.io/r/projecthydra-labs/hyrax) or [documentation coverage](https://inch-ci.org/github/projecthydra-labs/hyrax).
* Refactor away [code smells](https://codeclimate.com/github/projecthydra-labs/hyrax).

# Development

The [Sufia Development Guide](https://github.com/projecthydra/sufia/wiki/Sufia-Development-Guide) is for people who want to modify Hyrax itself, not an application that uses Hyrax.

# Release process

See the [release management process](https://github.com/projecthydra/sufia/wiki/Release-management-process).

# Acknowledgments

This software has been developed by and is brought to you by the Hydra community.  Learn more at the
[Project Hydra website](http://projecthydra.org/).

![Project Hydra Logo](http://hyr.ax/assets/images/hydra_logo.png)
