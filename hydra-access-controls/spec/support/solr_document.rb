class SolrDocument
  def initialize(source_doc={}, solr_response=nil)
    @source_doc = source_doc
  end

  def id
    fetch(:id)
  end

  def fetch(field, default = nil)
    @source_doc[field]
  end

  def [](field)
    @source_doc[field]
  end
end

