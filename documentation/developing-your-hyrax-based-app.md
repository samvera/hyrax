# Developing Your Hyrax-based Application

## Table of Contents

* [Introduction](#introduction)
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
  * [Toggling Features](#toggling-features)

## Introduction

A Hyrax-based application includes lots of dependencies. We provide a [Docker image for getting started with your Hyrax-based application](/CONTAINERS.md#docker-image-for-hyrax-based-applications).

**NOTE:** The Docker image describes the canonical dependencies. In a way, it is executable documentation. The following documentation is our best effort to transcribe that executable documentation into a narrative. In other words, this documentation may drift away from the Docker details.

You can also try [Running Hyrax-based application in local VM](https://github.com/samvera/hyrax/wiki/Hyrax-Development-Guide#running-hyrax-based-application-in-local-vm) which uses Ubuntu.

During development, running only the dependent services in a container environment may be beneficial. This avoids potential headaches concerning file permissions and eases the use of debugging tools. The application generation instructions below use [Lando](https://lando.dev) to achieve this setup.

This document contains instructions specific to setting up an app with __Hyrax
v5.1.0-beta1__. If you are looking for instructions on installing a different
version, be sure to select the appropriate branch or tag from the drop-down
menu above.

## Prerequisites

Prerequisites are required for both creating a Hyrax\-based app and contributing new features to Hyrax. After installing the prerequisites...

 * If you would like to create a new application using Hyrax follow the instructions for [Creating a Hyrax\-based app](#creating-a-hyrax-based-app).
 * If you would like to create new features for Hyrax follow the instructions for [Developing the Hyrax Engine](/README.md#developing-the-hyrax-engine).

Hyrax requires the following software to work:

1. [Solr](http://lucene.apache.org/solr/) version >= 5.x (tested up to 8.11.1, which includes the log4j library update)
1. [Fedora Commons](http://www.fedora-commons.org/) digital repository version >= 4.7.6 && < 5 (if using legacy ActiveFedora) or >= 6.5.1 (if using the Valkyrie Fedora adapter)
1. A SQL RDBMS ([PostgreSQL](https://www.postgresql.org) recommended)
1. [Redis](http://redis.io/), a key-value store
1. [ImageMagick](http://www.imagemagick.org/) with JPEG-2000 support
1. [FITS](#characterization) (tested up to version 1.5.0 -- avoid version 1.1.0)
1. [LibreOffice](#derivatives)
1. [ffmpeg](#transcoding)

**NOTE:** The [Hyrax Development Guide](https://github.com/samvera/hyrax/wiki/Hyrax-Development-Guide) has instructions for installing Solr and Fedora in a development environment.

### Characterization
#### Servlet FITS
FITS can be run as a web service. This has the benefit of improved performance by avoiding the slow startup time inherent to the local option below.

A container image is available for this purpose: [ghcr.io/samvera/fitsservlet](https://ghcr.io/samvera/fitsservlet)

#### Local FITS
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

`brew install libvpx ffmpeg`

Otherwise, to compile ffmpeg yourself, see the [ffmpeg compilation guide](https://trac.ffmpeg.org/wiki/CompilationGuide).

Once ffmpeg has been installed, enable transcoding by setting `config.enable_ffmpeg = true` in `config/initializers/hyrax.rb`.  You may also configure the location of ffmpeg using `config.ffmpeg_path`.

## Environments

**NOTE:** The following commands assume you're setting up Hyrax in a development environment (using the Rails built-in development environment). If you're setting up a production or production-like environment, you may wish to tell Rails that by prepending `RAILS_ENV=production` to the commands that follow, e.g., `rails`, `rake`, `bundle`, and so on.

## Ruby

First, you'll need a working Ruby installation. You can install this via your operating system's package manager -- you are likely to get farther with OSX, Linux, or UNIX than Windows but your mileage may vary -- but we recommend using a Ruby version manager such as [RVM](https://rvm.io/) or [rbenv](https://github.com/sstephenson/rbenv).

Hyrax supports Ruby 3.3. When starting a new project, we recommend using the latest Ruby 3.3 version.

## Redis

[Redis](http://redis.io/) is a key-value store that Hyrax uses to provide activity streams on repository objects and users, and helps when modifying order-persisting objects by managing multi-threaded actions on data (preventing race conditions as a global mutex).

Starting up Redis will depend on your operating system, and may in fact already be started on your system. You may want to consult the [Redis documentation](http://redis.io/documentation) for help doing this.

## Rails

Hyrax requires Rails 7. We recommend the latest Rails 7.2 release.

```
# If you don't already have Rails at your disposal...
gem install rails -v 7.2.2.1
```

### JavaScript runtime

Rails requires that you have a JavaScript runtime installed (e.g. nodejs or rubyracer). Either install nodejs or uncomment the `rubyracer` line in your Gemfile and run `bundle install` before running Hyrax's install generator.

**NOTE:** [nodejs](https://nodejs.org/en/) is preinstalled on most Mac computers and doesn't require a gem.  To test if nodejs is already installed, execute `node -v` in the terminal and the version of nodejs will be displayed if it is installed.

## Creating a Hyrax-based app

Create a new Hyrax-based application by following these steps in order.

**NOTE:** Starting with Hyrax v5, the generated application will use [Valkyrie](https://github.com/samvera/valkyrie) for repository persistence.
Use of [ActiveFedora](https://github.com/samvera/active_fedora) (instead of Valkyrie) is deprecated, but it should still be possible to reconfigure the generated application to use it.

### Development Prerequisites

These instructions assume the use of [Lando](https://lando.dev) and [Docker](https://docker.io) to manage the backend services needed by your Hyrax application. Follow the Lando installation instructions before proceeding, or have alternate providers for the services listed in the generated `.lando.yml`:
- Solr
- Postgres
- Redis
- FITS servlet
- Fedora (if not using Postgres)

### Generate the application

Generate a new Rails application using the template.

**NOTE:** `HYRAX_SKIP_WINGS` is needed here to avoid loading the Wings compatibility layer during the application generation process.

```shell
HYRAX_SKIP_WINGS=true rails _7.2.2.1_ new my_app --database=postgresql -m https://raw.githubusercontent.com/samvera/hyrax/hyrax-v5.1.0-beta1/template.rb
```

Generating a new Rails application using Hyrax's template above takes cares of a number of steps for you, including:

* Adding Hyrax (and any of its dependencies) to your application `Gemfile`, to declare that Hyrax is a dependency of your application
* Running `bundle install`, to install Hyrax and its dependencies
* Running Hyrax's install generator, to add a number of files that Hyrax requires within your Rails app, including e.g. database migrations

### Start Services

Start the background services managed by Lando. The

```shell
cd my_app
lando start
```

### Run Migrations/Seeds

This performs the following actions:

* Loading all of Hyrax's database migrations into your application's database
* Create default collection types (e.g. Admin Set, User Collection)
* Loading Hyrax's default workflows into your application's database

```shell
rails db:migrate
rails db:seed
```

**NOTE**: You will want to run these commands the first time this code is deployed to a new environment as well.

This creates the default administrative set -- into which all works will be deposited unless assigned to other administrative sets.
This command also makes sure that Hyrax's built-in workflows are loaded for your application and available for the default administrative set.

### Generate a work type

Using Hyrax requires generating at least one type of repository object, or "work type." Hyrax allows you to generate the work types required in your application by using a Rails generator-based tool. You may generate one or more of these work types.

Pass a (CamelCased) model name to Hyrax's work generator to get started, e.g.:

```
rails generate hyrax:work_resource MovingImage
```

If your applications requires your work type to be namespaced, namespaces can be included by adding a slash to the model name which creates a new class called `MovingImage` within the `My` namespace:

```shell
rails generate hyrax:work_resource My/MovingImage
```

You may wish to [customize your work type](https://github.com/samvera/hyrax/wiki/Customizing-your-work-types) now that it's been generated.

### Start Hyrax web server

Test-drive your new Hyrax application in development mode:

```shell
rails s
```

And now you should be able to browse to [localhost:3000](http://localhost:3000/) and see the application.

**NOTE:**
* This web server is purely for development purposes. You will want to use a more fully featured [web server](https://github.com/samvera/hyrax/wiki/Hyrax-Management-Guide#web-server) for production-like environments.
* For a fresh start, the data persisted in Lando can be wiped using `lando destroy`.

### Start background workers

Many of the services performed by Hyrax are resource intensive, and therefore are well suited to running as background jobs that can be managed and executed by a message queuing system. Examples include:

* File ingest
* Derivative generation
* Characterization
* Fixity
* Solr indexing

Hyrax implements these jobs using the Rails [ActiveJob](http://edgeguides.rubyonrails.org/active_job_basics.html) framework, allowing you to choose the message queue system of your choice.

For initial development, it is recommended that you change the default ActiveJob adapter from `:async` to `:inline`. This adapter will execute jobs immediately (in the foreground) as they are received. This can be accomplished by modifying the `.env` file:

```dotenv
HYRAX_ACTIVE_JOB_QUEUE=inline
```

For testing, it is recommended that you use the [built-in `:test` adapter](http://api.rubyonrails.org/classes/ActiveJob/QueueAdapters/TestAdapter.html) which stores enqueued and performed jobs, running only those configured to run during test setup. To do this, add the following to `config/environments/test.rb`:

```ruby
Rails.application.configure do
  # ...
  config.active_job.queue_adapter = :test
  # ...
end
```

**For production applications** you will want to use a more robust message queue system such as [Sidekiq](http://sidekiq.org/). The Hyrax Development Guide has a detailed walkthrough of [installing and configuring Sidekiq](https://github.com/samvera/hyrax/wiki/Using-Sidekiq-with-Hyrax).

### Create an Admin User

To access all of Hyrax's features you must be signed in as a user in the `admin` role. The default role management system uses the `config/role_map.yml` file to assign users to roles. For example:
```yaml
development:
  admin:
    - dev@test.internal
```

## Managing a Hyrax-based app

The [Hyrax Management Guide](https://github.com/samvera/hyrax/wiki/Hyrax-Management-Guide) provides tips for how to manage, customize, and enhance your Hyrax application, including guidance specific to:

* Production implementations
* Configuration of background workers
* Integration with e.g., Dropbox, Google Analytics, and Zotero
* Audiovisual transcoding with `ffmpeg`
* Setting up administrative users
* Metadata customization
* Virus checking
* Workflows

### Toggling Features

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
