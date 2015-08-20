# -*- encoding : utf-8 -*-
require 'rails/generators'

class CurationConcerns::Models::FulltextGenerator < Rails::Generators::Base
  source_root File.expand_path('../templates', __FILE__)

  desc """
This generator makes the following changes to your application:
 1. Copies solrconfig.xml into solr_conf/conf/
 2. Reconfigures jetty
       """

  def banner
    say_status("warning", "GENERATING CURATION_CONCERNS FULL-TEXT", :yellow)
  end

  # Copy CurationConcerns's solrconfig into the dir from which the jetty:config task pulls
  # CurationConcerns's solrconfig includes full-text extraction
  def copy_solr_config
    copy_file 'config/solrconfig.xml', 'solr_conf/conf/solrconfig.xml', force: true
  end

  # Copy config, schema, and jars into jetty dir if it exists
  def reconfigure_jetty
    rake "curation_concerns:jetty:config" if File.directory?('jetty')
  end
end
