# Generated via
#  `rails generate hyrax:work NamespacedWorks::NestedWork`
module Hyrax
  # Generated form for NamespacedWorks::NestedWork
  class NamespacedWorks::NestedWorkForm < Hyrax::Forms::WorkForm
    #include Hyrax::FormFields(:basic_metadata)
    include Hyrax::FormFields('namespaced_works/nested_work')

    self.model_class = ::NamespacedWorks::NestedWork
    self.terms += [:resource_type]
  end
end
