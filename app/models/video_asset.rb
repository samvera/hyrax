class VideoAsset < FileAsset
  def initialize(attrs = {})
    super(attrs)
    add_relationship(:has_model, "info:fedora/afmodel:FileAsset")
  end

  # Override ActiveFedora::Base.to_solr to...
  # For now just return solr_doc but will need to be changed 
  # to include datastreams in VideoAsset if added later
  def to_solr(solr_doc = Solr::Document.new, opts={})
    solr_doc
  end
end
