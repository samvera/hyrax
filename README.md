Gamma Project
=============
Gamma is a Ruby on Rails application utilizing the Blacklight and Hydra-head gems for integration with the search & indexing system, Solr, and the digital asset management platform, Fedora Commons.

Gamma is being developed as part of
[Penn State's Digital Stewardship Program](http://stewardship.psu.edu/).
Development on Gamma began as part of the prototype
[CAPS project](http://stewardship.psu.edu/2011/02/caps-a-curation-platform-prototype.html). Code
and documentation are freely available via [Github](http://github.com/psu-stewardship/gamma).


Installation Instructions
-------------------------

Copy and edit local DB, Fedora, and Solr configs

    cp config/database.yml.sample config/database.yml
    cp config/fedora.yml.sample config/fedora.yml
    cp config/database.yml.sample config/database.yml

TODO: Hint on how to tweak your configs (link to protected wikispaces page)

Install gems & migrate database

    bundle install
    rake db:create
    rake db:migrate

Setup test dbs and load fixtures

    RAILS_ENV=test rake db:create
    RAILS_ENV=test rake db:migrate
    rake db:data:load

Install [FITS](http://code.google.com/p/fits/) and put it in a
  directory on your PATH.

Get jetty & start it

    git submodule init
    git submodule update
    rake jetty:config
    rake jetty:start
  
Run the app
  
    rails server

Auditing All Datastreams
------------------------

RAILS\_ENV=production script/audit\_all_versions

Harvesting Authorities Locally
------------------------------

TODO: Flesh this out more

1. Harvest the authority
2. (OPTIONAL) Generate fixtures so other instances don't need to re-harvest
3. Register the vocabulary with a domain term in generic\_file\_rdf\_datastream.rb


