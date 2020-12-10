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
* [Dockerizing a Hyrax\-based App for Development](#dockerizing-a-hyrax-based-app-for-development)

## Introduction

A Hyrax-based application includes lots of dependencies. We provide a [Docker image for getting started with your Hyrax-based application](/CONTAINERS.md#docker-image-for-hyrax-based-applications).

<aside><p><em><strong>Note:</em></strong> The Docker image describes the canonical dependencies. In a way, it is executable documentation. The following documentation is our best effort to transcribe that executable documentation into a narrative. In other words, this documentation may drift away from the Docker details.</p></aside>

You can also try [Running Hyrax-based application in local VM](https://github.com/samvera/hyrax/wiki/Hyrax-Development-Guide#running-hyrax-based-application-in-local-vm) which uses Ubuntu.

This document contains instructions specific to setting up an app with __Hyrax
v3.0.0-rc2__. If you are looking for instructions on installing a different
version, be sure to select the appropriate branch or tag from the drop-down
menu above.

## Prerequisites

Prerequisites are required for both creating a Hyrax\-based app and contributing new features to Hyrax. After installing the prerequisites...

 * If you would like to create a new application using Hyrax follow the instructions for [Creating a Hyrax\-based app](#creating-a-hyrax-based-app).
 * If you would like to create new features for Hyrax follow the instructions for [Developing the Hyrax Engine](/README.md#developing-the-hyrax-engine).

Hyrax requires the following software to work:

1. [Solr](http://lucene.apache.org/solr/) version >= 5.x (tested up to 8.7.0)
1. [Fedora Commons](http://www.fedora-commons.org/) digital repository version >= 4.5.1 (tested up to 4.7.5)
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

`brew install libvpx ffmpeg`

Otherwise, to compile ffmpeg yourself, see the [ffmpeg compilation guide](https://trac.ffmpeg.org/wiki/CompilationGuide).

Once ffmpeg has been installed, enable transcoding by setting `config.enable_ffmpeg = true` in `config/initializers/hyrax.rb`.  You may also configure the location of ffmpeg using `config.ffmpeg_path`.

## Environments

Note here that the following commands assume you're setting up Hyrax in a development environment (using the Rails built-in development environment). If you're setting up a production or production-like environment, you may wish to tell Rails that by prepending `RAILS_ENV=production` to the commands that follow, e.g., `rails`, `rake`, `bundle`, and so on.

## Ruby

First, you'll need a working Ruby installation. You can install this via your operating system's package manager -- you are likely to get farther with OSX, Linux, or UNIX than Windows but your mileage may vary -- but we recommend using a Ruby version manager such as [RVM](https://rvm.io/) or [rbenv](https://github.com/sstephenson/rbenv).

Hyrax supports Ruby 2.5, 2.6, and 2.7. When starting a new project, we recommend using the latest Ruby 2.7 version.

## Redis

[Redis](http://redis.io/) is a key-value store that Hyrax uses to provide activity streams on repository objects and users, and helps when modifying order-persisting objects by managing multi-threaded actions on data (preventing race conditions as a global mutex).

Starting up Redis will depend on your operating system, and may in fact already be started on your system. You may want to consult the [Redis documentation](http://redis.io/documentation) for help doing this.

## Rails

Hyrax requires Rails 5. We recommend the latest Rails 5.2 release.

```
# If you don't already have Rails at your disposal...
gem install rails -v 5.2.4.3
```

### JavaScript runtime

Rails requires that you have a JavaScript runtime installed (e.g. nodejs or rubyracer). Either install nodejs or uncomment the `rubyracer` line in your Gemfile and run `bundle install` before running Hyrax's install generator.

NOTE: [nodejs](https://nodejs.org/en/) is preinstalled on most Mac computers and doesn't require a gem.  To test if nodejs is already installed, execute `node -v` in the terminal and the version of nodejs will be displayed if it is installed.

## Creating a Hyrax-based app

NOTE: The steps need to be done in order to create a new Hyrax based app.

Generate a new Rails application using the template.

```
rails _5.2.4.3_ new my_app -m https://raw.githubusercontent.com/samvera/hyrax/v3.0.0-rc2/template.rb
```

Generating a new Rails application using Hyrax's template above takes cares of a number of steps for you, including:

* Adding Hyrax (and any of its dependencies) to your application `Gemfile`, to declare that Hyrax is a dependency of your application
* Running `bundle install`, to install Hyrax and its dependencies
* Running Hyrax's install generator, to add a number of files that Hyrax requires within your Rails app, including e.g. database migrations
* Loading all of Hyrax's database migrations into your application's database
* Loading Hyrax's default workflows into your application's database
* Create default collection types (e.g. Admin Set, User Collection)

### Start servers

To test-drive your new Hyrax application in development mode, spin up the servers that Hyrax needs (Solr, Fedora, and Rails):

```
bin/rails hydra:server
```

And now you should be able to browse to [localhost:3000](http://localhost:3000/) and see the application.

Notes:
* This web server is purely for development purposes. You will want to use a more fully featured [web server](https://github.com/samvera/hyrax/wiki/Hyrax-Management-Guide#web-server) for production-like environments.
* You have the option to start each of these services individually.  More information on [solr_wrapper](https://github.com/cbeer/solr_wrapper) and [fcrepo_wrapper](https://github.com/cbeer/fcrepo_wrapper) will help you set this up.  Start rails with `rails s`.

### Start background workers

Many of the services performed by Hyrax are resource intensive, and therefore are well suited to running as background jobs that can be managed and executed by a message queuing system. Examples include:

* File ingest
* Derivative generation
* Characterization
* Fixity
* Solr indexing

Hyrax implements these jobs using the Rails [ActiveJob](http://edgeguides.rubyonrails.org/active_job_basics.html) framework, allowing you to choose the message queue system of your choice.

For initial development, it is recommended that you change the default ActiveJob adapter from `:async` to `:inline`. This adapter will execute jobs immediately (in the foreground) as they are received. This can be accomplished by adding the following to your `config/environments/development.rb`

```
class Application < Rails::Application
  # ...
  config.active_job.queue_adapter = :inline
  # ...
end
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

### Create default administrative set

**After** Fedora and Solr are running, create the default administrative set -- into which all works will be deposited unless assigned to other administrative sets -- by running the following command:

```
rails hyrax:default_admin_set:create
```

This command also makes sure that Hyrax's built-in workflows are loaded for your application and available for the default administrative set.

**NOTE**: You will want to run this command the first time this code is deployed to a new environment as well.

### Generate a work type

Using Hyrax requires generating at least one type of repository object, or "work type." Hyrax allows you to generate the work types required in your application by using a Rails generator-based tool. You may generate one or more of these work types.

Pass a (CamelCased) model name to Hyrax's work generator to get started, e.g.:

```
rails generate hyrax:work Work
```

or

```
rails generate hyrax:work MovingImage
```

If your applications requires your work type to be namespaced, namespaces can be included by adding a slash to the model name which creates a new class called `MovingImage` within the `My` namespace:

```
rails generate hyrax:work My/MovingImage
```

You may wish to [customize your work type](https://github.com/samvera/hyrax/wiki/Customizing-your-work-types) now that it's been generated.

### Enable notifications

Hyrax 2 uses a WebSocket-based user notifications system, which requires Redis. To enable user notifications, make sure that you have configured ActionCable to use Redis as the adapter in your application's `config/cable.yml`. E.g., for the `development` Rails environment:

```yaml
development:
  adapter: redis
  url: redis://localhost:6379
```

Using Rails up to version 5.1.4, ActionCable will not work with the 4.x series of the `redis` gem, so you will also need to pin your application to a 3.x release by adding this to your `Gemfile`:

```ruby
gem 'redis', '~> 3.0'
```

And then run `bundle update redis`.

Note that the Hyrax Management Guide contains additional information on [how to configure ActionCable in production environments](https://github.com/samvera/hyrax/wiki/Hyrax-Management-Guide#notifications).

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

## Dockerizing a Hyrax Based App for Development
It is now possible develop a Hyrax based app using a Docker workflow. The process utilizes **docker-compose** to build and run the services necessary for Hyrax based applications.

### Switch to Postgres
The image that you will build your app's image on uses **Postgres**. If you have just created your Hyrax-based app, for example, you'll need to update your `Gemfile`
	- `gem "sqlite3", "~> 1.3.0"` ---> `gem "pg"`

### Building the image
Next you'll want to build the image that your Hyrax container will run from. For that, you will need to create a Dockerfile, build the image from it, and push it to a repository you can fetch from later.

**Build and push image (assumes dockerhub.io registry)**
- Run `cd <hyrax_app_name>`
- Visit [samveralabs/hyrax](https://hub.docker.com/r/samveralabs/hyrax/tags) and grab the latest image **tag**
- Run `echo "FROM samveralabs/hyrax:<tag>" > Dockerfile` to create the Dockerfile
- Run `docker build . -t <hyrax_app_name>:dev`
- Run `docker push <your-docker-username>/<hyrax_app_name>:dev`

### Configure the docker-compose.yml
Since Hyrax relies on serveral different services to run, you'll need to set up a **docker-compose.yml** to tell Docker how to run all those services together.

- Create a **docker-compose.yml** file your application root
```
version: '3.8'
services:
  app: &app
    build:
      context: .
      target: hyrax-engine-dev
    image: <your-image-location> # (e.g. username/image-name:tag) 
    stdin_open: true
    tty: true
    user: root
    env_file:
      - .env
    environment:
      - RAILS_ROOT=/app/samvera/hyrax-webapp
    depends_on:
      - chrome
      - db_migrate
      - fcrepo
      - memcached
      - postgres
      - redis
      - solr
    ports:
      - 3000:3000
    volumes:
      - .:/app/samvera/hyrax-webapp
      - rails-public:/app/samvera/hyrax-webapp/public
      - rails-tmp:/app/samvera/hyrax-webapp/tmp

  chrome:
    image: selenium/standalone-chrome:3.141
    logging:
      driver: none
    volumes:
      - /dev/shm:/dev/shm
    shm_size: 2G
    ports:
      - "4444:4444"
      - "5959:5900"

  db_migrate:
    image: <your-image-location> # (e.g. username/image-name:tag) 
    user: root
    env_file:
      - .env
    entrypoint: ["sh", "-c"]
    command: db-migrate-seed.sh
    depends_on:
      - postgres
    volumes:
      - .:/app/samvera/hyrax-engine:cached
      - rails-public:/app/samvera/hyrax-webapp/public
      - rails-tmp:/app/samvera/hyrax-webapp/tmp

  postgres:
    image: postgres:latest
    restart: always
    environment:
      - POSTGRES_USER=hyrax_user
      - POSTGRES_PASSWORD=hyrax_password
      - POSTGRES_DB=hyrax
      - POSTGRES_HOST_AUTH_METHOD=trust
    ports:
      - "5432:5432"
    volumes:
      - db:/var/lib/postgresql/data

  fcrepo:
    image: cbeer/fcrepo4:4.7
    volumes:
      - fcrepo:/data
    ports:
      - 8080:8080
    environment:
      - JAVA_OPTS=${JAVA_OPTS} -Dfcrepo.modeshape.configuration="classpath:/config/file-simple/repository.json" -Dfcrepo.object.directory="/data/objects" -Dfcrepo.binary.directory="/data/binaries"

  memcached:
    image: bitnami/memcached
    ports:
      - '11211:11211'

  redis:
    image: redis:5-alpine
    volumes:
      - redis:/data

  solr:
    image: solr:8
    ports:
      - 8983:8983
    command:
      - sh
      - "-c"
      - "precreate-core hyrax_test /opt/solr/server/configsets/hyraxconf; precreate-core hyrax-valkyrie-test /opt/solr/server/configsets/hyraxconf; solr-precreate hyrax /opt/solr/server/configsets/hyraxconf"
    volumes:
      - solr_home:/opt/solr/server/solr
      - .dassie/solr/conf:/opt/solr/server/configsets/hyraxconf

volumes:
  db:
  fcrepo:
  rails-public:
  rails-tmp:
  redis:
  solr_home:
```
  - *Note*: This is essentially the same docker-compose.yml for engine development except without *.dassie* and pointing to *your image*

### Create an .env file
You'll need an **.env** file to pass some configuration along. You can start with the `.env` file from the engine repo, replacing `HYRAX_ENGINE_PATH` like so:
```
HYRAX_ENGINE_PATH=<relative-path-to-hyrax-repo>/hyrax/app/samvera/hyrax-engine
```

### Run it
With all that you should be able to tell Docker to spin up your Hyrax app.

- Run `docker-compose up`
- When all the containers have finished spinning up, your app should be reachable at **localhost:3000**

### Run some specs

**To run the specs**
- In another terminal window, run `docker-compose exec web sh`
	- This will open the **web container's** shell
- At **container's** the shell prompt, run `rspec` to see the pending specs
- Open up the app repo in your text editor of choice and write some specs
- Running `rspec` will reflect your spec changes
