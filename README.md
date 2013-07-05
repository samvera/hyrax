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

Sufia needs the following software to work:
* Solr
* Fedora Commons
* A SQL RDBMS (MySQL, SQLite)
* Redis
* Ruby



## Creating an application
### Generate base Rails install
```rails new my_app```
### Add gems to Gemfile
```
gem 'blacklight'
gem 'hydra-head'
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
rails g sufia -f
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
#### Modify app/assets/application.css
Add this line:
```
 *= require sufia
```
**Remove** this line:  
```*= require_tree .```  

_Removing the require_tree from application.css will ensure you're not loading the blacklight.css.  This is because blacklight's css styling does not mix well with sufia's default styling._ 


#### Modify app/assets/application.js

Add this line:
```
//= require sufia
```

### Install Fits.sh
http://code.google.com/p/fits/downloads/list
Download a copy of fits & unpack it somewhere on your PATH.

### Start background workers
```
COUNT=4 QUEUE=* rake environment resque:work
```
See https://github.com/defunkt/resque for more options

### If you want to enable transcoding of video, instal ffmpeg version 1.0+
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
