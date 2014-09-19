module CleanerHelper
  # Removes any data in Fedora and Solr
  def cleanup_jetty
    ActiveFedora::Base.delete_all
    Blacklight.solr.delete_by_query("*:*")
    Blacklight.solr.commit
  end

  RSpec.configure do |config|
    config.include CleanerHelper
  end
end
