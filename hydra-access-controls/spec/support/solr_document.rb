class SolrDocument
  def initialize(source_doc={}, solr_response=nil)
    @source_doc = source_doc
  end
  def fetch(field, default)
    @source_doc[field]
  end

  def [](field)
    @source_doc[field]
  end
end

