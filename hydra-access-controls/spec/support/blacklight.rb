require 'blacklight'

module Blacklight
  def self.solr_file
    File.expand_path(File.join(File.dirname(__FILE__), "config", "solr.yml"))
  end
end
