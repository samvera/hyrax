# -*- encoding : utf-8 -*-
require 'jettywrapper'

module Hydra
  class Jetty < Rails::Generators::Base

    desc """
Installs a jetty container with a solr and fedora installed in it.

Requires system('unzip... ') to work, probably won't work on Windows.

"""

    def download_jetty
      Jettywrapper.unzip
    end


  end
end

