# frozen_string_literal: true

module Hyrax
  module Forms
    ##
    # @api public
    #
    # @example defining a form class using HydraEditor-like configuration
    #   class MonographForm < Hyrax::Forms::PcdmObjectForm(Monograph)
    #     self.required_fields = [:title, :creator, :rights_statement]
    #     # other WorkForm-like configuration here
    #   end
    def self.PcdmObjectForm(work_class) # rubocop:disable Naming/MethodName
      Class.new(Hyrax::Forms::PcdmObjectForm) do
        self.model_class = work_class

        ##
        # @return [String]
        def self.inspect
          return "Hyrax::Forms::PcdmObjectForm(#{model_class})" if name.blank?
          super
        end
      end
    end

    ##
    # @api public
    #
    # Returns the form class associated with a given model.
    def self.ResourceForm(model_class) # rubocop:disable Metrics/MethodLength, Metrics/PerceivedComplexity, Naming/MethodName
      @resource_forms ||= {}.compare_by_identity
      @resource_forms[model_class] ||=
        # +#respond_to?+ needs to be used here, not +#try+, because Dry::Types
        # overrides the latter??
        if model_class.respond_to?(:pcdm_collection?) && model_class.pcdm_collection?
          if model_class <= Hyrax::AdministrativeSet
            Hyrax.config.administrative_set_form
          else
            Hyrax.config.pcdm_collection_form
          end
        elsif model_class.respond_to?(:pcdm_object?) && model_class.pcdm_object?
          if model_class.respond_to?(:file_set?) && model_class.file_set?
            Hyrax.config.file_set_form
          else
            Hyrax.config.pcdm_object_form_builder.call(model_class)
          end
        else
          Hyrax::Forms::ResourceForm
        end
    end
  end
end
