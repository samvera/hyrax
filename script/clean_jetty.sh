#!/bin/bash
#
# Deletes everything in the hydra-jetty instances of Solr and Fedora
# https://github.com/psu-stewardship/scholarsphere/wiki/Cleaning-up-hydra-jetty

rake jetty:stop
(cd jetty && git clean -df && git checkout .)
rake jetty:config
rake jetty:start

