module CurationConcern::HasRepresentative
  extend ActiveSupport::Concern

  included do
    has_attributes :representative, datastream: :properties, multiple: false
  end

  def to_solr(solr_doc={})
    super(solr_doc).tap do |solr_doc|
      solr_doc[Solrizer.solr_name('representative', :stored_searchable)] = representative
    end
  end

end
