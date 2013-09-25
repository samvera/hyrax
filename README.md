# Sufia [![Version](https://badge.fury.io/rb/sufia.png)](http://badge.fury.io/rb/sufia) [![Build Status](https://travis-ci.org/projecthydra/sufia.png?branch=master)](https://travis-ci.org/projecthydra/sufia) [![Dependency Status](https://gemnasium.com/projecthydra/sufia.png)](https://gemnasium.com/projecthydra/sufia)

## What is Sufia?
Sufia is a component that adds self-deposit institutional repository features to a Rails app. 
Sufia is created with Ruby on Rails and builds on the Hydra Framework.

Sufia has the following features:

* Multiple file, or folder, upload
* Flexible user- and group-based access controls
* Transcoding of audio and video files 
* Generation and validation of identifiers
* Fixity checking
* Version control
* Characterization of uploaded files
* Forms for batch editing metadata
* Faceted search and browse (based on Blacklight)
* Social media interaction
* User profiles
* User dashboard for file management
* Highlighted files on profile
* Sharing w/ groups and users
* User notifications
* Activity streams
* Background jobs
* Single-use links

## Sufia needs the following software to work:
1. Solr
1. [Fedora Commons](http://www.fedora-commons.org/) digital repository
1. A SQL RDBMS (MySQL, SQLite)
1. [Redis](http://redis.io/) key-value store
1. [ImageMagick](http://www.imagemagick.org/)
1. Ruby

#### !! Ensure that you have all of the above components installed before you continue. !!

## Creating an application
### Generate base Rails install
```rails new my_app```
### Add gems to Gemfile
```
gem 'sufia'
gem 'kaminari', github: 'harai/kaminari', branch: 'route_prefix_prototype'  # required to handle pagination properly in dashboard. See https://github.com/amatsuda/kaminari/pull/322
gem 'jettywrapper'
gem 'font-awesome-sass-rails'
```
Then `bundle install`

Note the line with kaminari listed as a dependency.  This is a temporary fix to address a problem in the current release of kaminari.  Technically you should not have to list kaminari, which is a dependency of blacklight and sufia. 

### Run the blacklight, hydra and sufia generators
```
rails g blacklight --devise
rails g hydra:head -f
bundle install
rails g sufia -f
rm public/index.html
```

### Run the migrations

```
rake db:migrate
```

### Get a copy of hydra-jetty
```
rails g hydra:jetty
rake jetty:config
rake jetty:start
```

### If you want to use the assets that ship with Sufia...
#### Modify app/assets/stylesheets/application.css
Add this line:
```
 *= require sufia
```
**Remove** this line:  
```*= require_tree .```  

_Removing the require_tree from application.css will ensure you're not loading the blacklight.css.  This is because blacklight's css styling does not mix well with sufia's default styling._ 


#### Modify app/assets/javascripts/application.js

Add this line:
```
//= require sufia
```

### Install Fits.sh
1. Go to http://code.google.com/p/fits/downloads/list and download a copy of fits & unpack it somewhere on your Machine.
1. Give your system access to fits
    1. By adding the path to fits.sh to your excutable PATH. (ex. in your .bashrc)
        * OR
    1. By adding/changing config/initializers/sufia.rb to point to your fits location:   `config.fits_path = "/<your full path>/fits.sh"`
1. You may additionally need to chmod the fits.sh (chmod a+x fits.sh)
1. You may need to restart your shell to pick up the changes to you path
1. You should be able to run "fits.sh" from the command line and see a help message

### Start background workers
**Note:** Resque relies on the [redis](http://redis.io/) key-value store.  You must install [redis](http://redis.io/) on your system and *have redis running* in order for this command to work.
To start redis, you usually want to call the `redis-server` command.

```
QUEUE=* rake environment resque:work
```

For production you may want to set up a config/resque-pool.yml and run resque pool in daemon mode

```
resque-pool --daemon --environment development start
```

See https://github.com/defunkt/resque for more options

### If you want to enable transcoding of video, install ffmpeg version 1.0+
#### On a mac
Use homebrew:
```
brew install ffmpeg --with-libvpx --with-libvorbis
```

#### On Ubuntu Linux
See https://ffmpeg.org/trac/ffmpeg/wiki/UbuntuCompilationGuide

## Developers:
This information is for people who want to modify the engine itself, not an application that uses the engine:
### Create fixtures
```
# configure jetty & start jetty (if you haven't already)
rake jetty:config
rake jetty:start

# load sufia fixtures
rake sufia:fixtures:create sufia:fixtures:generate
rake fixtures

# run the tests
rake clean spec
bundle exec cucumber features
```
