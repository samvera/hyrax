# Generated via
#  `rails generate hyrax:work NamespacedWorks::NestedWork`
class NamespacedWorks::NestedWork < ActiveFedora::Base
  include ::Hyrax::WorkBehavior
  #include Hyrax::Schema(:basic_metadata)
  include Hyrax::Schema('namespaced_works/nested_work')

  self.indexer = NamespacedWorks::NestedWorkIndexer
  # Change this to restrict which works can be added as a child.
  # self.valid_child_concerns = []
  validates :title, presence: { message: 'Your work must have a title.' }

  # This must be included at the end, because it finalizes the metadata
  # schema (by adding accepts_nested_attributes)
  include ::Hyrax::BasicMetadata
#  id_blank = proc { |attributes| attributes[:id].blank? }
#
#  class_attribute :controlled_properties
#  self.controlled_properties = [:based_near]
#  accepts_nested_attributes_for :based_near, reject_if: id_blank, allow_destroy: true
  accepts_nested_attributes_for :created
end
