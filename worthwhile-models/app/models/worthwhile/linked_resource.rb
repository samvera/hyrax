module Worthwhile
  class LinkedResource < ActiveFedora::Base
    include ::CurationConcern::Work
    include Sufia::GenericFile::Metadata

    property :target_url, predicate: ::RDF::DC.source, multiple: false

    belongs_to :batch, predicate:  ActiveFedora::RDF::Fcrepo::RelsExt.isPartOf, class_name: 'ActiveFedora::Base'

    validates :url, presence: true

    self.human_readable_short_description = "An arbitrary URL reference."
    include ActionView::Helpers::SanitizeHelper

    def url=(url)
      u = URI::Parser.new.parse(url)
      return unless [URI::HTTP, URI::HTTPS, URI::FTP].include?(u.class)
      # content.dsLocation = u.to_s
      return self.target_url = u.to_s
    end

    def url
      self.target_url
    end

    def to_s
      if label && !label.empty?
        label
      else
        url
      end
    end

    def to_solr(solr_doc={})
      super(solr_doc).tap do |solr_doc|
        Solrizer.set_field(solr_doc, 'url', url, :stored_searchable)
      end
    end
  end
end