![Logo](https://raw.githubusercontent.com/samvera/hyrax/gh-pages/assets/images/hyrax_logo_horizontal_white_background.png)

Code: [![Version](https://badge.fury.io/rb/hyrax.png)](http://badge.fury.io/rb/hyrax)
[![Build Status](https://travis-ci.org/samvera/hyrax.png?branch=master)](https://travis-ci.org/samvera/hyrax)
[![Coverage Status](https://coveralls.io/repos/github/samvera/hyrax/badge.svg?branch=master)](https://coveralls.io/github/samvera/hyrax?branch=master)
[![Code Climate](https://codeclimate.com/github/samvera/hyrax/badges/gpa.svg)](https://codeclimate.com/github/samvera/hyrax)
[![Dependency Update Status](https://gemnasium.com/samvera/hyrax.png)](https://gemnasium.com/samvera/hyrax)
[![Dependency Maintenance Status](https://dependencyci.com/github/samvera/hyrax/badge)](https://dependencyci.com/github/samvera/hyrax)

Docs: [![Documentation Status](https://inch-ci.org/github/samvera/hyrax.svg?branch=master)](https://inch-ci.org/github/samvera/hyrax)
[![API Docs](http://img.shields.io/badge/API-docs-blue.svg)](http://rubydoc.info/gems/hyrax)
[![Contribution Guidelines](http://img.shields.io/badge/CONTRIBUTING-Guidelines-blue.svg)](./.github/CONTRIBUTING.md)
[![Apache 2.0 License](http://img.shields.io/badge/APACHE2-license-blue.svg)](./LICENSE)

Jump in: [![Slack Status](http://slack.samvera.org/badge.svg)](http://slack.samvera.org/)
[![Ready Tickets](https://badge.waffle.io/samvera/hyrax.png?label=ready&milestone=2.x%20series&title=Ready)](https://waffle.io/samvera/hyrax?milestone=2.x%20series)

# Table of Contents

  * [What is Hyrax?](#what-is-hyrax)
    * [Feature list](#feature-list)
  * [Help](#help)
  * [Getting started](#getting-started)
    * [Quickstart](#quickstart)
    * [Prerequisites](#prerequisites)
      * [Characterization](#characterization)
      * [Derivatives](#derivatives)
      * [Transcoding](#transcoding)
    * [Environments](#environments)
    * [Ruby](#ruby)
    * [Redis](#redis)
    * [Rails](#rails)
      * [JavaScript runtime](#javascript-runtime)
  * [Creating a Hyrax\-based app](#creating-a-hyrax-based-app)
    * [Start servers](#start-servers)
    * [Start background workers](#start-background-workers)
    * [Create default administrative set](#create-default-administrative-set)
    * [Generate a work type](#generate-a-work-type)
    * [Enable notifications](#enable-notifications)
  * [Managing a Hyrax\-based app](#managing-a-hyrax-based-app)
    * [Toggling features](#toggling-features)
  * [License](#license)
  * [Contributing](#contributing)
  * [Development](#development)
    * [Workflow Relationship Diagram](#workflow-relationship-diagram)
  * [Release process](#release-process)
  * [Acknowledgments](#acknowledgments)

# What is Hyrax?

Hyrax is a front-end based on the robust [Samvera](http://samvera.org) framework, providing a user interface for common repository features. Hyrax offers the ability to create repository object types on demand, to deposit content via multiple configurable workflows, and to describe content with flexible metadata. Numerous optional features may be turned on in the administrative dashboard or added through plugins. It is implemented as a Rails engine, so it may be the base of, or added to, a Rails application. Hyrax is the consolidation of Sufia and the CurationConcerns gems and behaves in much the same way.

## Feature list

Hyrax has many features. [Read more about what they are and how to turn them on](https://github.com/samvera/hyrax/wiki/Feature-matrix). See the [Hyrax Management Guide](https://github.com/samvera/hyrax/wiki/Hyrax-Management-Guide) to learn more.

For non-technical documentation about Hyrax, see the Hyrax [documentation site](http://hyr.ax/).

# Help

The Samvera community is here to help. Please see our [support guide](./.github/SUPPORT.md).

# Getting started

This document contains instructions specific to setting up an app with __Hyrax
v2.0.0.rc2__. If you are looking for instructions on installing a different
version, be sure to select the appropriate branch or tag from the drop-down
menu above.

## Quickstart

If you're looking to spin up a vanilla Hyrax application very quickly for demonstration purposes, you may be interested in [the samvera-vagrant project](https://github.com/samvera-labs/samvera-vagrant) which may be used to "kick the tires" of Hyrax and [Hyku](https://github.com/samvera-labs/hyku). It requires VirtualBox and Vagrant.

## Prerequisites

Prerequisites are required for both creating a Hyrax\-based app and contributing new features to Hyrax. After installing the prerequisites...

 * If you would like to create a new application using Hyrax follow the instructions for [Creating a Hyrax\-based app](#creating-a-hyrax-based-app).
 * If you would like to create new features for Hyrax follow the instructions for [Contributing](#contributing) and [Development](#development).

Hyrax requires the following software to work:

1. [Solr](http://lucene.apache.org/solr/) version >= 5.x (tested up to 6.4.1)
1. [Fedora Commons](http://www.fedora-commons.org/) digital repository version >= 4.5.1 (tested up to 4.7.1)
1. A SQL RDBMS (MySQL, PostgreSQL), though **note** that SQLite will be used by default if you're looking to get up and running quickly
1. [Redis](http://redis.io/), a key-value store
1. [ImageMagick](http://www.imagemagick.org/) with JPEG-2000 support
1. [FITS](#characterization) version 1.0.x (1.0.5 is known to be good, 1.1.0 is known to be bad: https://github.com/harvard-lts/fits/issues/140)
1. [LibreOffice](#derivatives)
1. [ffmpeg](#transcoding)

**NOTE: The [Hyrax Development Guide](https://github.com/samvera/hyrax/wiki/Hyrax-Development-Guide) has instructions for installing Solr and Fedora in a development environment.**

### Characterization

FITS can be installed on OSX using Homebrew by running the command: `brew install fits`

**OR**

1. Go to http://projects.iq.harvard.edu/fits/downloads and download a copy of FITS (see above to pick a known working version) & unpack it somewhere on your machine.
1. Mark fits.sh as executable: `chmod a+x fits.sh`
1. Run `fits.sh -h` from the command line and see a help message to ensure FITS is properly installed
1. Give your Hyrax app access to FITS by:
    1. Adding the full fits.sh path to your PATH (e.g., in your .bash\_profile), **OR**
    1. Changing `config/initializers/hyrax.rb` to point to your FITS location:  `config.fits_path = "/<your full path>/fits.sh"`

### Derivatives

Install [LibreOffice](https://www.libreoffice.org/). If `which soffice` returns a path, you're done. Otherwise, add the full path to soffice to your PATH (in your `.bash_profile`, for instance). On OSX, soffice is **inside** LibreOffice.app. Your path may look like "/path/to/LibreOffice.app/Contents/MacOS/"

You may also require [ghostscript](http://www.ghostscript.com/) if it does not come with your compiled version LibreOffice. `brew install ghostscript` should resolve the dependency on an OSX-based machine with Homebrew installed.

**NOTE**: Derivatives are served from the filesystem in Hyrax.

### Transcoding

Hyrax includes support for transcoding audio and video files with ffmpeg > 1.0 installed.

On OSX, you can use Homebrew to install ffmpeg:

`brew install ffmpeg --with-fdk-aac --with-libvpx --with-libvorbis`

Otherwise, to compile ffmpeg yourself, see the [ffmpeg compilation guide](https://trac.ffmpeg.org/wiki/CompilationGuide).

## Environments

Note here that the following commands assume you're setting up Hyrax in a development environment (using the Rails built-in development environment). If you're setting up a production or production-like environment, you may wish to tell Rails that by prepending `RAILS_ENV=production` to the commands that follow, e.g., `rails`, `rake`, `bundle`, and so on.

## Ruby

First, you'll need a working Ruby installation. You can install this via your operating system's package manager -- you are likely to get farther with OSX, Linux, or UNIX than Windows but your mileage may vary -- but we recommend using a Ruby version manager such as [RVM](https://rvm.io/) or [rbenv](https://github.com/sstephenson/rbenv).

We recommend either Ruby 2.4 or the latest 2.3 version.

## Redis

[Redis](http://redis.io/) is a key-value store that Hyrax uses to provide activity streams on repository objects and users, and to prevent race conditions as a global mutex when modifying order-persisting objects.

Starting up Redis will depend on your operating system, and may in fact already be started on your system. You may want to consult the [Redis documentation](http://redis.io/documentation) for help doing this.

## Rails

Hyrax requires Rails 5. We recommend the latest Rails 5.0 release.

```
# If you don't already have Rails at your disposal...
gem install rails -v 5.0.6
```

### JavaScript runtime

Rails requires that you have a JavaScript runtime installed (e.g. nodejs or rubyracer). Either install nodejs or uncomment the `rubyracer` line in your Gemfile and run `bundle install` before running Hyrax's install generator.

NOTE: nodejs is preinstalled on most Mac computers and doesn't require a gem.  To test if nodejs is already installed, execute `node -v` in the terminal and the version of nodejs will be displayed if it is installed.

# Creating a Hyrax-based app

NOTE: The steps need to be done in order to create a new Hyrax based app.

Generate a new Rails application using the template.

```
rails _5.0.6_ new my_app -m https://raw.githubusercontent.com/samvera/hyrax/v2.0.0.rc2/template.rb
```

Generating a new Rails application using Hyrax's template above takes cares of a number of steps for you, including:

* Adding Hyrax (and any of its dependencies) to your application `Gemfile`, to declare that Hyrax is a dependency of your application
* Running `bundle install`, to install Hyrax and its dependencies
* Running Hyrax's install generator, to add a number of files that Hyrax requires within your Rails app, including e.g. database migrations
* Loading all of Hyrax's database migrations into your application's database
* Loading Hyrax's default workflows into your application's database

## Start servers

To test-drive your new Hyrax application in development mode, spin up the servers that Hyrax needs (Solr, Fedora, and Rails):

```
bin/rails hydra:server
```

And now you should be able to browse to [localhost:3000](http://localhost:3000/) and see the application.

Notes:
* This web server is purely for development purposes. You will want to use a more fully featured [web server](#web-server) for production-like environments.
* You have the option to start each of these services individually.  More information on [solr_wrapper](https://github.com/cbeer/solr_wrapper) and [fcrepo_wrapper](https://github.com/cbeer/fcrepo_wrapper) will help you set this up.  Start rails with `rails s`.

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

**For production applications** you will want to use a more robust message queue system such as [Sidekiq](http://sidekiq.org/). The Hyrax Development Guide has a detailed walkthrough of [installing and configuring Sidekiq](https://github.com/samvera/hyrax/wiki/Using-Sidekiq-with-Hyrax).

## Create default administrative set

**After** Fedora and Solr are running, create the default administrative set -- into which all works will be deposited unless assigned to other administrative sets -- by running the following command:

```
bin/rails hyrax:default_admin_set:create
```

This command also makes sure that Hyrax's built-in workflows are loaded for your application and available for the default administrative set.

**NOTE**: You will want to run this command the first time this code is deployed to a new environment as well.

## Generate a work type

Using Hyrax requires generating at least one type of repository object, or "work type." Hyrax allows you to generate the work types required in your application by using a Rails generator-based tool. You may generate one or more of these work types.

Pass a (CamelCased) model name to Hyrax's work generator to get started, e.g.:

```
rails generate hyrax:work Work
```

or

```
rails generate hyrax:work MovingImage
```

If your applications requires your work type to be namespaced, namespaces can be included in the by adding a slash to the model name which creates a new class called `MovingImage` within the `My` namespace:

```
rails generate hyrax:work My/MovingImage
```

You may wish to [customize your work type](https://github.com/samvera/hyrax/wiki/Customizing-your-work-types) now that it's been generated.

## Enable notifications

Hyrax 2 uses a WebSocket-based user notifications system, which requires Redis. To enable user notifications, make sure that you have configured ActionCable to use Redis as the adapter in your application's `config/cable.yml`. E.g., for the `development` Rails environment:

``` yaml
development:
  adapter: redis
  url: redis://localhost:6379
```

Note that the Hyrax Management Guide contains additional information on [how to configure ActionCable in production environments](https://github.com/samvera/hyrax/wiki/Hyrax-Management-Guide#notifications).

# Managing a Hyrax-based app

The [Hyrax Management Guide](https://github.com/samvera/hyrax/wiki/Hyrax-Management-Guide) provides tips for how to manage, customize, and enhance your Hyrax application, including guidance specific to:

* Production implementations
* Configuration of background workers
* Integration with e.g., Dropbox, Google Analytics, and Zotero
* Audiovisual transcoding with `ffmpeg`
* Setting up administrative users
* Metadata customization
* Virus checking
* Workflows

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

If you'd like to help the development effort and you're not sure where to get started, you can always grab a ticket in the "Ready" column from our [Waffle board](https://waffle.io/samvera/hyrax). There are other ways to help, too.

* The Hyrax user interface is translated into a number of languages, and many of these translations come from Google Translate. If you are a native or fluent speaker of a non-English language, your help improving these translations are most welcome. (Hyrax currently supports English, Spanish, Chinese, Italian, German, French, and Portuguese.)
  * Do you see English in the application where you would expect to see one of the languages above? If so, [file an issue](https://github.com/samvera/hyrax/issues/new) and suggest a translation, please.
* [Contribute a user story](https://github.com/samvera/hyrax/issues/new).
* Help us improve [Hyrax's test coverage](https://coveralls.io/r/samvera/hyrax) or [documentation coverage](https://inch-ci.org/github/samvera/hyrax).
* Refactor away [code smells](https://codeclimate.com/github/samvera/hyrax).

# Development

The [Hyrax Development Guide](https://github.com/samvera/hyrax/wiki/Hyrax-Development-Guide) is for people who want to modify Hyrax itself, not an application that uses Hyrax.

## Workflow Relationship Diagram

* [Entity Relationship Diagram](./artifacts/entity-relationship-diagram.pdf)

# Release process

See the [release management process](https://github.com/samvera/hyrax/wiki/Release-management-process).

# Acknowledgments

This software has been developed by and is brought to you by the Samvera community.  Learn more at the
[Samvera website](http://samvera.org/).

![Samvera Logo](https://wiki.duraspace.org/download/thumbnails/87459292/samvera-fall-font2-200w.png?version=1&modificationDate=1498550535816&api=v2)
