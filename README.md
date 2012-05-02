ScholarSphere
=============
ScholarSphere is a Ruby on Rails application utilizing the Blacklight and Hydra-head gems for integration with the search & indexing system, Solr, and the digital asset management platform, Fedora Commons.

ScholarSphere is being developed as part of
[Penn State's Digital Stewardship Program](http://stewardship.psu.edu/).
Development on ScholarSphere began as part of the prototype
[CAPS project](http://stewardship.psu.edu/2011/02/caps-a-curation-platform-prototype.html). Code
and documentation are freely available via [Github](http://github.com/psu-stewardship/scholarsphere).

For more information, read the [ScholarSphere development docs](https://github.com/psu-stewardship/scholarsphere/wiki).

Installation Instructions
-------------------------

Copy and edit local DB, Fedora, and Solr configs

    cp config/solr.yml.sample config/solr.yml
    cp config/fedora.yml.sample config/fedora.yml
    cp config/database.yml.sample config/database.yml

Install gems & migrate database

    bundle install
    rake db:create
    rake db:migrate

Setup test dbs and load fixtures

    RAILS_ENV=test rake db:create
    RAILS_ENV=test rake db:migrate
    RAILS_ENV=test rake scholarsphere:fixtures:create
    RAILS_ENV=test rake scholarsphere:fixtures:refresh

Install [FITS](http://code.google.com/p/fits/) and put it in a
  directory on your PATH.

Get jetty & start it

    git submodule init
    git submodule update
    rake jetty:config
    rake jetty:start

Run delayed jobs

    script/delayed_job start (or stop)
  
Run the app
  
    rails server

Auditing All Datastreams
------------------------

RAILS_ENV=production script/audit_all_versions

Harvesting Authorities Locally
------------------------------

The easiest way to pull in authorities is to load the pre-generated
set that are serialized as fixtures.

    rake db:data:load

To harvest more authorities:

1. Harvest the authority
2. (OPTIONAL) Generate fixtures so other instances don't need to re-harvest
3. Register the vocabulary with a domain term in generic_file_rdf_datastream.rb


