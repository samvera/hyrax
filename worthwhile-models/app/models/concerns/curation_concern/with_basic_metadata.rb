# Basic metadata for all Works
# Required fields:
#   dc:title
#   dc:rights
#
# Optional fields:
#   dc:contributor
#   dc:coverage
#   dc:creator
#   dc:date
#   dc:description
#   dc:format
#   dc:identifier
#   dc:language
#   dc:publisher
#   dc:relation
#   dc:source
#   dc:subject
#   dc:type
module CurationConcern::WithBasicMetadata
  extend ActiveSupport::Concern

  included do
    has_metadata "descMetadata", type: ::GenericWorkMetadata
    # Validations that apply to all types of Work AND Collections
    validates_presence_of :title,  message: 'Your work must have a title.'


    # Single-value fields
    has_attributes :created, :date_modified, :date_uploaded, datastream: :descMetadata, multiple: false

    # Multi-value fields
    has_attributes :contributor, :creator, :coverage, :date, :description, :content_format, :identifier,
                  :language, :publisher, :relation, :rights, :source, :subject, :title, :type,
                  datastream: :descMetadata, multiple: true
  end


  # TODO created and date_uploaded?
  # TODO created and date_created
  # has_attributes :date_uploaded, :date_modified, :title, :description,
  #               datastream: :descMetadata, multiple: false
  #
  # has_attributes :related_url, :based_near, :part_of, :creator, :contributor,
  #                :tag, :rights, :publisher, :date_created, :subject, :resource_type,
  #                 :identifier, :language,
  #               datastream: :descMetadata, multiple: true

end
