# This stands in for an object to be created from the BatchUploadChangeSet.
# It should never actually be persisted in the repository.
# The properties on this form should be copied to a real work type.
class BatchUploadItem < Valkyrie::Resource
  include Hyrax::WorkBehavior
  # This must come after the WorkBehavior because it finalizes the metadata
  # schema (by adding accepts_nested_attributes)
  include ::Hyrax::BasicMetadata

  attr_accessor :payload_concern # a Class name: what is this a batch of?
end
