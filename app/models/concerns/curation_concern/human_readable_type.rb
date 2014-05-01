module CurationConcern
  module HumanReadableType
    extend ActiveSupport::Concern

    module ClassMethods
      def human_readable_type
        name.demodulize.titleize
      end
    end

    def human_readable_type
      self.class.human_readable_type
    end

    def to_solr(solr_doc={}, opts={})
      super(solr_doc, opts)
      solr_doc[Solrizer.solr_name('human_readable_type',:facetable)] = human_readable_type
      solr_doc[Solrizer.solr_name('human_readable_type', :stored_searchable)] = human_readable_type
      return solr_doc
    end

  end
end

