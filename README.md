# Sufia

Code: [![Version](https://badge.fury.io/rb/sufia.png)](http://badge.fury.io/rb/sufia)
[![Build Status](https://travis-ci.org/projecthydra/sufia.png?branch=master)](https://travis-ci.org/projecthydra/sufia)
[![Coverage Status](https://coveralls.io/repos/github/projecthydra/sufia/badge.svg?branch=master)](https://coveralls.io/github/projecthydra/sufia?branch=master)
[![Code Climate](https://codeclimate.com/github/projecthydra/sufia/badges/gpa.svg)](https://codeclimate.com/github/projecthydra/sufia)
[![Dependency Update Status](https://gemnasium.com/projecthydra/sufia.png)](https://gemnasium.com/projecthydra/sufia)
[![Dependency Maintenance Status](https://dependencyci.com/github/projecthydra/sufia/badge)](https://dependencyci.com/github/projecthydra/sufia)

Docs: [![Documentation Status](https://inch-ci.org/github/projecthydra/sufia.svg?branch=master)](https://inch-ci.org/github/projecthydra/sufia)
[![API Docs](http://img.shields.io/badge/API-docs-blue.svg)](http://rubydoc.info/gems/sufia)
[![Contribution Guidelines](http://img.shields.io/badge/CONTRIBUTING-Guidelines-blue.svg)](./.github/CONTRIBUTING.md)
[![Apache 2.0 License](http://img.shields.io/badge/APACHE2-license-blue.svg)](./LICENSE)

Jump in: [![Slack Status](http://slack.projecthydra.org/badge.svg)](http://slack.projecthydra.org/)
[![Ready Tickets](https://badge.waffle.io/projecthydra/sufia.png?label=ready&milestone=7.2.0&title=Ready)](https://waffle.io/projecthydra/sufia?milestone=7.2.0)

# Table of Contents

  * [What is Sufia?](#what-is-sufia)
    * [Feature list](#feature-list)
  * [Help](#help)
  * [Getting started](#getting-started)
    * [Prerequisites](#prerequisites)
      * [Characterization](#characterization)
      * [Derivatives](#derivatives)
    * [Environments](#environments)
    * [Ruby](#ruby)
  * [Creating a Sufia\-based app](#creating-a-sufia-based-app)
    * [Rails](#rails)
    * [Sufia's Ruby\-related dependencies](#sufias-ruby-related-dependencies)
    * [Install Sufia](#install-sufia)
    * [Generate a primary work type](#generate-a-primary-work-type)
    * [Database tables and indexes](#database-tables-and-indexes)
    * [Start Redis](#start-redis)
    * [Start Solr](#start-solr)
    * [Start FCRepo](#start-fcrepo)
    * [Spin up the web server](#spin-up-the-web-server)
  * [Managing a Sufia\-based app](#managing-a-sufia-based-app)
  * [License](#license)
  * [Contributing](#contributing)
  * [Development](#development)
  * [Release process](#release-process)
  * [Acknowledgments](#acknowledgments)

# What is Sufia?

Sufia uses the full power of [Hydra](http://projecthydra.org/) and extends it to provide a user interface around common repository features and social features (see below). Sufia offers self-deposit and proxy deposit workflows, and mediated deposit workflows are being developed in a community sprint running from September-December 2016. Sufia delivers its rich and growing set of features via a modern, responsive user interface. It is implemented as a Rails engine, so it is meant to be added to existing Rails apps.

## Feature list

Sufia has the following features:

* Multiple file upload, and folder uploads (for Chrome browser only)
* Flexible user- and group-based access controls
* Transcoding of audio and video files
* Generation and validation of identifiers
* Generation of derivatives (served from the filesystem, not the repository)
* Fixity checking
* Version control
* Characterization of uploaded files
* Forms for batch editing metadata
* Faceted search and browse
* Social media interaction
* User profiles
* User dashboard for file management
* Highlighted files on profile
* Sharing w/ groups and users
* User notifications
* Activity streams
* Background jobs
* Single-use links
* Google Analytics for usage statistics
* Integration w/ cloud storage providers
* Google Scholar-specific metadata embedding
* Schema.org microdata, Open Graph meta tags, and Twitter cards for rich snippets
* User-managed collections for grouping files
* Full-text indexing & searching
* Responsive, fluid, Bootstrap 3-based UI
* Dynamically configurable featured works and researchers on homepage
* Proxy deposit and transfers of ownership
* Integration with Zotero for automatic population of user content
* Suggested values from controlled vocabularies provided by [Questioning Authority](https://github.com/projecthydra-labs/questioning_authority)
* [ResourceSync](http://www.openarchives.org/rs/1.0/resourcesync) capability lists and resource lists
* Administrative sets (curated collections)
* Administrative dashboard, w/ feature flippers to turn features on and off in the UI
* Contact form
* Customizable banner image
* Flexible object model: upload and manage single-file works, multi-file works, zero-file works, and works-within-works
* Geonames integration for location-oriented metadata fields
* Virus detection for uploaded files
* Citation formatting suggestions

See the [Sufia Management Guide](https://github.com/projecthydra/sufia/wiki/Sufia-Management-Guide) to learn which features listed above are turned on by default and which require configuration.

For non-technical documentation about Sufia, see its [documentation site](http://sufia.io/).

# Help

If you have questions or need help, please email [the Hydra community tech list](mailto:hydra-tech@googlegroups.com) or stop by the #dev channel in [the Hydra community Slack team](https://wiki.duraspace.org/pages/viewpage.action?pageId=43910187#Getintouch!-Slack).

# Getting started

This document contains instructions specific to setting up an app with __Sufia
v7.1.0__. If you are looking for instructions on installing a different
version, be sure to select the appropriate branch or tag from the drop-down
menu above.

Prerequisites are required for both Creating a Sufia\-based app and Contributing new features to Sufia.
After installing the Prerequisites:
 * If you would like to create a new application using Sufia follow the instructions for [Creating a Sufia\-based app](#creating-a-sufia-based-app).
 * If you would like to create new features for Sufia follow the instructions for [Contributing](#contributing) and [Development](#development).

## Prerequisites

Sufia 7.x requires the following software to work:

1. Solr version >= 5.x (tested up to 6.2.0)
1. [Fedora Commons](http://www.fedora-commons.org/) digital repository version >= 4.5.1 (tested up to 4.6.0)
1. A SQL RDBMS (MySQL, PostgreSQL), though **note** that SQLite will be used by default if you're looking to get up and running quickly
1. [Redis](http://redis.io/), a key-value store
1. [ImageMagick](http://www.imagemagick.org/) with JPEG-2000 support
1. [FITS](#characterization) version 0.8.x (0.8.5 is known to be good)
1. [LibreOffice](#derivatives)

**NOTE: If you do not already have Solr and Fedora instances you can use in your development environment, you may use hydra-jetty (instructions are provided below to get you up and running quickly and with minimal hassle).**

### Characterization

1. Go to http://projects.iq.harvard.edu/fits/downloads and download a copy of FITS (see above to pick a known working version) & unpack it somewhere on your machine.
1. Mark fits.sh as executable: `chmod a+x fits.sh`
1. Run `fits.sh -h` from the command line and see a help message to ensure FITS is properly installed
1. Give your Sufia app access to FITS by:
    1. Adding the full fits.sh path to your PATH (e.g., in your .bash_profile), **OR**
    1. Changing `config/initializers/sufia.rb` to point to your FITS location:  `config.fits_path = "/<your full path>/fits.sh"`

### Derivatives

Install [LibreOffice](https://www.libreoffice.org/). If `which soffice` returns a path, you're done. Otherwise, add the full path to soffice to your PATH (in your `.bash_profile`, for instance). On OSX, soffice is **inside** LibreOffice.app. Your path may look like "/<your full path to>/LibreOffice.app/Contents/MacOS/"

You may also require [ghostscript](http://www.ghostscript.com/) if it does not come with your compiled version LibreOffice. `brew install ghostscript` should resolve the dependency on a mac.

**NOTE**: derivatives are served from the filesystem in Sufia 7, which is a difference from earlier versions of Sufia.

## Environments

Note here that the following commands assume you're setting up Sufia in a development environment (using the Rails built-in development environment). If you're setting up a production or production-like environment, you may wish to tell Rails that by prepending `RAILS_ENV=production` to the commands that follow, e.g., `rails`, `rake`, `bundle`, and so on.

## Ruby

First, you'll need a working Ruby installation. You can install this via your operating system's package manager -- you are likely to get farther with OSX, Linux, or UNIX than Windows but your mileage may vary -- but we recommend using a Ruby version manager such as [RVM](https://rvm.io/) or [rbenv](https://github.com/sstephenson/rbenv).

We recommend either Ruby 2.3 or the latest 2.2 version.

# Creating a Sufia-based app

## Rails

Generate a new Rails application. We recommend the latest Rails 5.0 or 4.2 release.

```
gem install rails -v 5.0.0.1
rails new my_app
```

## Sufia's Ruby-related dependencies

Add the following lines to your application's Gemfile.

```
gem 'sufia', '7.1.0'
```

Then install Sufia as a dependency of your app via `bundle install`

## Install Sufia

Install Sufia into your app using its built-in install generator. This step adds a number of files that Sufia requires within your Rails app, including e.g. a number of database migrations.

```
rails generate sufia:install -f
```

## Generate a primary work type

While earlier versions of Sufia came with a pre-defined object model, Sufia 7.x and greater allow you to specify your primary work type by using tooling provided by the CurationConcerns gem. Work on the 7.x series will include adding support for users to generate an arbitrary number of work types, not **just** a primary work type. At this time we do *not* recommend generating multiple work types.

Pass a (CamelCased) model name to Sufia's work generator to get started, e.g.:

```
rails generate sufia:work Work
```

or

```
rails generate sufia:work MovingImage
```

## Database tables and indexes

Now that Sufia's required database migrations have been generated into your app, you'll need to load them into your application's database.

```
rake db:migrate
```

## Start Redis

[Redis](http://redis.io/) is a key-value store that Sufia uses to provide activity streams on repository objects and users, and to prevent race conditions as a global mutex when modifying order-persisting objects.

Starting up Redis will depend on your operating system, and may in fact already be started on your system. You may want to consult the [Redis documentation](http://redis.io/documentation) for help doing this.

## Start Solr

If you already have an instance of Solr that you would like to use, you may skip this step.  Open a new terminal window and type:
```
solr_wrapper -d solr/config/ --collection_name hydra-development
```

You can check to see if Solr is started by going to [localhost:8983](http://localhost:8983/).

## Start FCRepo

If you already have an instance of FCRepo that you would like to use, you may skip this step.  Open a new terminal window and type:

```
fcrepo_wrapper -p 8984
```

You can check to see if FCRepo is started by going to [localhost:8984](http://localhost:8984/).

## Spin up the web server

To test-drive your new Sufia application, spin up the web server that Rails provides:

```
rails server
```

And now you should be able to browse to [localhost:3000](http://localhost:3000/) and see the application. Note that this web server is purely for development purposes; you will want to use a more fully featured [web server](#web-server) for production-like environments.

# Managing a Sufia-based app

The [Sufia Management Guide](https://github.com/projecthydra/sufia/wiki/Sufia-Management-Guide) provides tips for how to manage, customize, and enhance your Sufia application, including guidance specific to:

* Production implementations
* Configuration of background workers
* Integration with e.g., Dropbox, Google Analytics, and Zotero
* Audiovisual transcoding with `ffmpeg`
* Setting up administrative users
* Metadata customization

# License

Sufia is available under [the Apache 2.0 license](LICENSE.md).

# Contributing

We'd love to accept your contributions.  Please see our guide to [contributing to Sufia](./.github/CONTRIBUTING.md).

If you'd like to help the development effort and you're not sure where to get started, you can always grab a ticket in the "Ready" column from our [Waffle board](https://waffle.io/projecthydra/sufia). There are other ways to help, too.

* [Contribute a user story](https://github.com/projecthydra/sufia/issues/new).
* Help us improve [Sufia's test coverage](https://coveralls.io/r/projecthydra/sufia) or [documentation coverage](https://inch-ci.org/github/projecthydra/sufia).
* Refactor away [code smells](https://codeclimate.com/github/projecthydra/sufia).

# Development

The [Sufia Development Guide](https://github.com/projecthydra/sufia/wiki/Sufia-Development-Guide) is for people who want to modify Sufia itself, not an application that uses Sufia.

# Release process

See the [release management process](https://github.com/projecthydra/sufia/wiki/Release-management-process).

# Acknowledgments

This software has been developed by and is brought to you by the Hydra community.  Learn more at the
[Project Hydra website](http://projecthydra.org/).

![Project Hydra Logo](http://sufia.io/assets/images/hydra_logo.png)
