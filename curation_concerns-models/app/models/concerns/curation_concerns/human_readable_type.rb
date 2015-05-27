module CurationConcerns
   module HumanReadableType
    extend ActiveSupport::Concern

    included do
      class_attribute :human_readable_short_description, :human_readable_type
      self.human_readable_type = name.demodulize.titleize
    end

    def human_readable_type
      self.class.human_readable_type
    end

    def to_solr(solr_doc={})
      super(solr_doc).tap do |solr_doc|
        solr_doc[Solrizer.solr_name('human_readable_type',:facetable)] = human_readable_type
        solr_doc[Solrizer.solr_name('human_readable_type', :stored_searchable)] = human_readable_type
      end
    end

  end
end

