# frozen_string_literal: true

module Hyrax
  module Specs
    ##
    # This configuration serves the goal of exposing Hyrax's factories to downstream
    # implementations, allowing for greater re-use of these complicated and foundational testing
    # tools.
    #
    # One envisioned scenario is that a downstream application wants to extend two factories
    # (e.g. admin_set and permission_template).  Given that Hyrax's :admin_set factory references
    # :permission_template factory, it would be convenient to provide a means to change that factory
    # name.
    #
    # The implementation pattern is as follows:
    #
    # - Define a factory using a "hard-coded" symbol.
    # - Within a factory, when referencing another factory, do so by way of this class.
    # - Within a spec, reference a factory by a "hard-coded" symbol.
    #
    # Downstream implementations can adjust the Hyrax::Specs::FactoryName, which in turn means that
    # the factories defined in Hyrax and re-used downstream, will use those newly specified
    # factories.  Those newly specified factories *might* inherit from the default factory.
    class FactoryName
      class_attribute :admin_set, default: :admin_set
      class_attribute :admin_set_lw, default: :admin_set_lw
      class_attribute :adminset_lw, default: :adminset_lw
      class_attribute :collection, default: :collection
      class_attribute :collection_lw, default: :collection_lw
      class_attribute :collection_lw_type, default: :collection_lw_type
      class_attribute :collection_type, default: :collection_type
      class_attribute :collection_type_participant, default: :collection_type_participant
      class_attribute :default_adminset, default: :default_adminset
      class_attribute :embargoed_work, default: :embargoed_work
      class_attribute :file_set, default: :file_set
      class_attribute :hyrax_admin_set, default: :hyrax_admin_set
      class_attribute :hyrax_collection, default: :hyrax_collection
      class_attribute :hyrax_embargo, default: :hyrax_embargo
      class_attribute :hyrax_file_set, default: :hyrax_file_set
      class_attribute :hyrax_lease, default: :hyrax_lease
      class_attribute :hyrax_resource, default: :hyrax_resource
      class_attribute :hyrax_work, default: :hyrax_work
      class_attribute :leased_work, default: :leased_work
      class_attribute :monograph, default: :monograph
      class_attribute :permission, default: :permission
      class_attribute :permission_template, default: :permission_template
      class_attribute :permission_template_access, default: :permission_template_access
      class_attribute :typeless_collection, default: :typeless_collection
      class_attribute :uploaded_file, default: :uploaded_file
      class_attribute :user, default: :user
      class_attribute :user_collection_type, default: :user_collection_type
      class_attribute :work, default: :work
      class_attribute :workflow, default: :workflow
      class_attribute :workflow_action, default: :workflow_action
    end
  end
end
