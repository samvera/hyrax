# Sufia

## What is Sufia?
Sufia is a web application that serves as a self-deposit institutional repository.
Sufia created with Ruby on Rails and builds on the Hydra Framework.

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
gem 'jettywrapper'
gem 'font-awesome-sass-rails'
```
Then `bundle install`

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


### If you want to use the assets that ship with Sufia...
#### add the following to application.css
```
 *= require sufia
```
You'll want to ensure you're not loading the blacklight.css, so remove this line ```*= require_tree .```

#### Add the following to application.js
```
//= require sufia
```

### Install Fits.sh
http://code.google.com/p/fits/downloads/list

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
# start jetty
git submodule init && git submodule update
rake jetty:config
rake jetty:start

# load sufia fixtures
rake sufia:fixtures:create sufia:fixtures:generate
rake fixtures

# run the tests
rake clean spec
bundle exec cucumber features
```
