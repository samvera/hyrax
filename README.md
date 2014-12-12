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

## License

Sufia is available under [the Apache 2.0 license](LICENSE.md).

## Contributing

We'd love to accept your contributions.  Please see our guide to [contributing to Sufia](CONTRIBUTING.md).

## Sufia needs the following software to work:
1. Solr
1. [Fedora Commons](http://www.fedora-commons.org/) digital repository
1. A SQL RDBMS (MySQL, SQLite)
1. [Redis](http://redis.io/) key-value store
1. [ImageMagick](http://www.imagemagick.org/)
1. Ruby

#### !! Ensure that you have all of the above components installed before you continue. !!

## Need Help?

If you have questions or need help, please email [the Hydra community development list](mailto:hydra-tech@googlegroups.com).

## Creating an application

### Generate base Rails install

```rails new my_app```

### Add gems to Gemfile

```
gem 'sufia'
gem 'kaminari', github: 'harai/kaminari', branch: 'route_prefix_prototype'  # required to handle pagination properly in dashboard. See https://github.com/amatsuda/kaminari/pull/322
```

Then `bundle install`

### Run the sufia generator
```
rails generate sufia:install -f
```

### Run the migrations

```
rake db:migrate
```

### Get a copy of jetty (Solr and Fedora)
```
rake jetty:clean
rake sufia:jetty:config
rake jetty:start
```

### To use the CSS and JavaScript and other assets that ship with Sufia...

#### Modify app/assets/stylesheets/application.css
Add this line:
```
 *= require sufia
```
**Remove** this line:
```*= require_tree .```

_Removing the require_tree from application.css will ensure you're not loading the blacklight.css.  This is because blacklight's css styling does not mix well with sufia's default styling._

#### Modify app/assets/javascripts/application.js

Add this line at the bottom of the file:
```
//= require sufia
```

**Remove** this line, if present (typically, when using Rails 4):
```
//= require turbolinks
```

Turbolinks does not mix well with Blacklight.

### Install Notes

#### Kaminari

The line with kaminari listed as a dependency in Gemfile is a temporary fix to address a
[problem](https://github.com/amatsuda/kaminari/pull/322) in the current release of kaminari.
Technically you should not have to list kaminari, which is a dependency of blacklight and sufia.

### Proxies and Transfers

To add proxies and transfers to your Sufia 4-based app, run the 'sufia:models:proxies' generator and then run 'rake db:migrate'.

### Analytics

Sufia provides support for capturing usage information via Google Analytics and for displaying usage stats in the UI.

#### Capturing usage

To enable the Google Analytics javascript snippet, make sure that `config.google_analytics_id` is set in your app within the `config/initializers/sufia.rb` file. A Google Analytics ID typically looks like _UA-99999999-1_.

#### Displaying usage

To display data from Google Analytics in the UI, first head to the Google Developers Console and create a new project:

https://console.developers.google.com/project

Let's assume for now Google assigns it a project ID of _foo-bar-123_. It may take a few seconds for this to complete (watch the Activities bar near the bottom of the browser).  Once it's complete, enable the Google+ and Google Analytics APIs here (note: this is an example URL -- you'll have to change the project ID to match yours):

https://console.developers.google.com/project/apps~foo-bar-123/apiui/api

Finally, head to this URL (note: this is an example URL -- you'll have to change the project ID to match yours):

https://console.developers.google.com/project/apps~foo-bar-537/apiui/credential

And create a new OAuth client ID.  When prompted for the type, use the "Service Account" type.  This will give you the OAuth client ID, a client email address, a private key file, a private key secret/password, which you will need in the next step.

Then run this generator:

```
rails g sufia:models:usagestats
```

The generator will create a configuration file at _config/analytics.yml_.  Edit that file to reflect the information that the Google Developer Console gave you earlier, namely you'll need to provide it:

* The path to the private key
* The password/secret for the privatekey
* The OAuth client email
* An application name (you can make this up)
* An application version (you can make this up)

Lastly, you will need to set `config.analytics = true` and `config.analytic_start_date` in _config/initializers/sufia.rb_ and ensure that the OAuth client email
has the proper access within your Google Analyics account.  To do so, go to the _Admin_ tab for your Google Analytics account.
Click on _User Management_, in the _Account_ column, and add "Read & Analyze" permissions for the OAuth client email address.

### To use browse-everything

Sufia provides built-in support for the [browse-everything](https://github.com/projecthydra/browse-everything) gem, which provides a consolidated file picker experience for selecting files from [DropBox](http://www.dropbox.com),
[Skydrive](https://skydrive.live.com/), [Google Drive](http://drive.google.com),
[Box](http://www.box.com), and a server-side directory share.

To activate browse-everything in your sufia app, run the browse-everything config generator

```
rails g browse_everything:config
```

This will generate a file at _config/browse_everything_providers.yml_. Open that file and enter the API keys for the providers that you want to support in your app.  For more info on configuring browse-everything, go to the [project page](https://github.com/projecthydra/browse-everything) on github.

After running the browse-everything config generator and setting the API keys for the desired providers, an extra tab will appear in your app's Upload page allowing users to pick files from those providers and submit them into your app's repository.

*Note*: If you want to use the built-in browse-everything support, _you need to include the browse-everything css and javascript files_. If you already included the sufia css and javascript (see [above](#if-you-want-to-use-the-css-and-javascript-and-other-assets-that-ship-with-sufia)), then you don't need to do anything.  Otherwise, follow the instructions in the [browse-everything README page](https://github.com/projecthydra/browse-everything)

*If your config/initializers/sufia.rb was generated with sufia 3.7.2 or older*, then you need to add this line to an initializer (probably _config/initializers/sufia.rb _):
```ruby
config.browse_everything = BrowseEverything.config
```

### Install Fits.sh
1. Go to http://code.google.com/p/fits/downloads/list and download a copy of fits & unpack it somewhere on your machine.  You can also install fits on OSX with homebrew `brew install fits` (you may also have to create a symlink from `fits.sh -> fits` in the next step).
1. Give your system access to fits
    1. By adding the path to fits.sh to your excutable PATH. (ex. in your .bashrc)
        * OR
    1. By adding/changing config/initializers/sufia.rb to point to your fits location:   `config.fits_path = "/<your full path>/fits.sh"`
1. You may additionally need to chmod the fits.sh (chmod a+x fits.sh)
1. You may need to restart your shell to pick up the changes to your path
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
brew install ffmpeg --with-fdk-aac --with-libvpx --with-libvorbis
```
### Tag Cloud
Sufia provides a tag cloud on the home page.  To change which field is displayed in that cloud, change the value of `config.tag_cloud_field_name` in the `blacklight_config` section of your CatalogController.  For example:
```ruby
configure_blacklight do |config|
  ...

  # Specify which field to use in the tag cloud on the homepage.
  # To disable the tag cloud, comment out this line.
  config.tag_cloud_field_name = Solrizer.solr_name("tag", :facetable)
end
```

If your CatalogController was generated by a version of sufia older than 3.7.3 you need to add that line to the blacklight configuration in order to make the tag cloud appear.

The contents of the cloud are retrieved as JSON from Blacklight's CatalogController#facet method.  If you need to change how that content is returned (ie. if you need to limit the number of results), override the `render_facet_list_as_json` method in your CatalogController.

#### On Ubuntu Linux
See https://ffmpeg.org/trac/ffmpeg/wiki/UbuntuCompilationGuide

## Developers:
This information is for people who want to modify the engine itself, not an application that uses the engine:

### run the tests

```
rake jetty:start
redis-server
rake engine_cart:clean
rake engine_cart:generate
rake spec
```

### Change validation behavior

To change what happens to files that fail validation add an after_validation hook
```
    after_validation :dump_infected_files

    def dump_infected_files
      if Array(errors.get(:content)).any? { |msg| msg =~ /A virus was found/ }
        content.content = errors.get(:content)
        save
      end
    end
```

## Acknowledgments

This software has been developed by and is brought to you by the Hydra community.  Learn more at the
[Project Hydra website](http://projecthydra.org)

![Project Hydra Logo](https://github.com/uvalib/libra-oa/blob/a6564a9e5c13b7873dc883367f5e307bf715d6cf/public/images/powered_by_hydra.png?raw=true)
