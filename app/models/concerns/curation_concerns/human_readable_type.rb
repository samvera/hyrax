module CurationConcerns
  module HumanReadableType
    extend ActiveSupport::Concern

    included do
      class_attribute :human_readable_type
      self.human_readable_type = name.demodulize.titleize
    end

    def to_solr(solr_doc = {})
      super(solr_doc).tap do |doc|
        doc[Solrizer.solr_name('human_readable_type', :facetable)] = human_readable_type
        doc[Solrizer.solr_name('human_readable_type', :stored_searchable)] = human_readable_type
      end
    end
  end
end
