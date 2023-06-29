# frozen_string_literal: true

# Generated via
#  `rails generate hyrax:collection_resource CollectionResource`
class CollectionResource < Hyrax::PcdmCollection
  # @note Do not directly update `basic_metadata.yaml`.  It is also used by works.
  #
  # To change metadata for collections
  # * extend by adding fields to `/config/metadata/collection_resource.yaml`
  # * remove all basic metadata
  #   * if you generated `with_basic_metadata` and now don't want any basic metadata,
  #       comment out or delete the schema include statement for `:basic_metadata`
  #   * update form and indexer classes to also remove the `:basic_metadata` schema include
  # * remove some basic metadata
  #   * comment out or delete the schema include statement for `:basic_metadata`
  #   * update form and indexer classes to also remove the `:basic_metadata` schema include
  #   * copy fields you want to keep from `/config/metadata/basic_metadata.yaml`
  #       to `/config/metadata/collection_resource.yaml`
  # * override basic metadata
  #   * copy fields you want to override from `/config/metadata/basic_metadata.yaml`
  #       to `/config/metadata/collection_resource.yaml`
  #   * update them in `config/metadata/collection_resource.yaml to have the desired
  #       characteristics
  #
  # Alternative:
  # * comment out or delete schema include statements
  # * add Valkyrie attributes to this class
  # * update form and indexer to process the attributes
  #
  include Hyrax::Schema(:basic_metadata)
  include Hyrax::Schema(:collection_resource)
end
