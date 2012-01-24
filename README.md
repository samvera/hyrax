Gamma Project
=============
Gamma extends work done on a prototype to implement a reliable, scalable, and performant platform on which to develop curatorial, archival, and publishing applications. The focus of Gamma will be on developing a web application for basic ingest, curation, search, and display of digital assets atop a publishing & curation platform. Ingest and curation services will be piloted by select University stakeholders during the project; search and display functions will be available as a new beta service to the University community and the general public. 

Gamma is being developed as part of [Penn State's Digital Stewardship Program](http://stewardship.psu.edu/).  Development on Gamma began as part of the prototype [CAPS project](http://stewardship.psu.edu/2011/02/caps-a-curation-platform-prototype.html). Code is freely available via [Github](http://github.com/psu-stewardship/gamma).

Gamma is a Ruby on Rails application utilizing the Blacklight and Hydra-head gems for integration with the search & indexing system, Solr, and the digital asset management platform, Fedora Commons.

Baseline Application Features
----------------------------
* Upload files to archival storage 
* Describe an object with metadata
* Assign controls to authorize access by classes of users  
* Verify the integrity of an object 
* Assign objects to collections 
* Publish an object for public search and display


Installation Instructions
-------------------------

Install gems & migrate database

 bundle install
 rake db:migrate
 
Get jetty & start it

 git submodule init
 git submodule update
 rake jetty:config
 rake jetty:start