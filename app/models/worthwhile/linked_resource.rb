module Worthwhile
  class LinkedResource < ActiveFedora::Base
    include ::CurationConcern::Work

    has_file_datastream "content", control_group: 'E'
    has_metadata "descMetadata", type: GenericFileRdfDatastream
    
    belongs_to :batch, property: :is_part_of, class_name: 'ActiveFedora::Base'

    validates :url, presence: true

    self.human_readable_short_description = "An arbitrary URL reference."
    include ActionView::Helpers::SanitizeHelper
    
    has_attributes :date_uploaded, :date_modified, :title, :description, datastream: :descMetadata, multiple: false

    # Creator is multiple to match Sufia::GenericFile#creator
    has_attributes :creator, datastream: :descMetadata, multiple: true

    def url=(url)
      u = URI::Parser.new.parse(url)
      return unless [URI::HTTP, URI::HTTPS, URI::FTP].include?(u.class)
      content.dsLocation = u.to_s
    end

    def url
      content.dsLocation
    end

    def to_s
      url
    end

    def to_solr(solr_doc={}, opts={})
      super
      Solrizer.set_field(solr_doc, 'url', url, :stored_searchable)
      solr_doc
    end
  end
end

