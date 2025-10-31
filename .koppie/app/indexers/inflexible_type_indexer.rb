# frozen_string_literal: true

# Generated via
#  `rails generate hyrax:work_resource InflexibleType`
class InflexibleTypeIndexer < Hyrax::Indexers::PcdmObjectIndexer(InflexibleType)
  if Hyrax.config.work_include_metadata?
    include Hyrax::Indexer(:core_metadata)
    include Hyrax::Indexer(:basic_metadata)
    include Hyrax::Indexer(:inflexible_type)
  end
  check_if_flexible(InflexibleType)

  # Uncomment this block if you want to add custom indexing behavior:
  #  def to_solr
  #    super.tap do |index_document|
  #      index_document[:my_field_tesim]   = resource.my_field.map(&:to_s)
  #      index_document[:other_field_ssim] = resource.other_field
  #    end
  #  end
end
