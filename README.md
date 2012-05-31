ScholarSphere
=============
ScholarSphere is a Ruby on Rails application utilizing the Blacklight and Hydra-head gems for integration with the search & indexing system, Solr, and the digital asset management platform, Fedora Commons.  The application runs on Fedora 3.4.2 and Solr 3.5.0.

ScholarSphere is being developed as part of
[Penn State's Digital Stewardship Program](http://stewardship.psu.edu/).
Development on ScholarSphere began as part of the prototype
[CAPS project](http://stewardship.psu.edu/2011/02/caps-a-curation-platform-prototype.html). Code
and documentation are freely available via [Github](http://github.com/psu-stewardship/scholarsphere).

For more information, read the [ScholarSphere development docs](https://github.com/psu-stewardship/scholarsphere/wiki).

Installation Instructions
-------------------------

Install system dependencies
  
 * libmysqlclient-dev (if running MySQL as RDBMS)
 * libmysql-ruby (if running MySQL as RDBMS)
 * libsqlite3-dev (if running SQLite as RDBMS)
 * libmagick-dev
 * libmagickwand-dev
 * [FITS](http://code.google.com/p/fits/) -- put it in a
  directory on your PATH

Copy and *edit* database, Fedora, and Solr configs

    cp config/database.yml.sample config/database.yml
    cp config/fedora.yml.sample config/fedora.yml
    cp config/solr.yml.sample config/solr.yml

Install gems & migrate database

    bundle install
    rake db:create
    rake db:migrate

If you'll be developing ScholarSphere, setup test dbs and load fixtures

    RAILS_ENV=test rake db:create
    RAILS_ENV=test rake db:migrate
    RAILS_ENV=test rake scholarsphere:fixtures:create
    RAILS_ENV=test rake scholarsphere:fixtures:refresh

Get jetty & start it

    git submodule init
    git submodule update
    rake jetty:config
    rake jetty:start

Run delayed jobs workers

    script/delayed_job start 
  
Run the app
  
    rails server

Auditing All Datastreams
------------------------

    RAILS_ENV=production script/audit_repository

You'll probably want to cron this in production environments.

Harvesting Authorities Locally
------------------------------

The easiest way to pull in authorities is to load the pre-generated
set that are serialized as fixtures.

    rake db:data:load

To harvest more authorities:

1. Harvest the authority
2. (OPTIONAL) Generate fixtures so other instances don't need to re-harvest
3. Register the vocabulary with a domain term in generic_file_rdf_datastream.rb


