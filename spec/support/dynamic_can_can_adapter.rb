# frozen_string_literal: true

module Hyrax
  module Test
    ##
    # A `CanCan::ModelAdapter` shim for both active_fedora and valkyrie resources for tests
    # This shim handles the case where controllers are loaded with an ActiveFedora collection class
    # then a different test mocks Hyrax.config.collection_class and calls the same controller again.
    # This adapter will check the value in Hyrax.config and use the appropriate adapter
    class DynamicCanCanAdapter < CanCan::ModelAdapters::AbstractAdapter
      ##
      # @param [Class] member_class
      def self.for_class?(_member_class)
        true
      end

      ##
      # @param [Class] model_class
      # @param [String] id
      #
      # @return [Hyrax::Resource]
      #
      # @raise Hyrax::ObjectNotFoundError
      def self.find(model_class, id)
        if ValkyrieCanCanAdapter.for_class?(model_class) ||
           really_valkyrie_collection?(model_class) ||
           really_valkyrie_admin_set?(model_class)
          ValkyrieCanCanAdapter.find(model_class, id)
        else
          CanCan::ModelAdapters::DefaultAdapter.find(model_class, id)
        end
      end

      def self.really_valkyrie_collection?(model_class)
        (Hyrax.config.collection_class == Hyrax::PcdmCollection || Hyrax.config.collection_class < Hyrax::Resource) &&
          (model_class == ::Collection || model_class < ::Collection)
      end

      def self.really_valkyrie_admin_set?(model_class)
        (Hyrax.config.admin_set_class == Hyrax::AdministrativeSet || Hyrax.config.admin_set_class < Hyrax::Resource) &&
          (model_class == AdminSet || model_class < AdminSet)
      end
    end
  end
end
