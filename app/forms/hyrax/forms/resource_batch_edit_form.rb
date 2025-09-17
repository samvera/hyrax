# frozen_string_literal: true
module Hyrax
  module Forms
    class ResourceBatchEditForm < Hyrax::Forms::ResourceForm
      # batch edit is unfortunately all or nothing when it comes to flexible metadata
      # because the form could be a mix of AF records, Valkyrie records and Flexible Valkyrie records
      # we have no real way of turning this on or off more precisely
      include Hyrax::FormFields(:batch_edit_metadata) unless Hyrax.primary_work_type.flexible?

      include Hyrax::ContainedInWorksBehavior
      include Hyrax::DepositAgreementBehavior
      include Hyrax::LeaseabilityBehavior
      include Hyrax::PermissionBehavior

      class_attribute :terms
      self.required_fields = []
      self.model_class = Valkyrie.config.resource_class_resolver.call(Hyrax.primary_work_type.to_s)
      self.terms = Hyrax::Forms::BatchEditForm.terms

      # Contains a list of titles of all the works in the batch
      attr_accessor :names

      # @param [Hyrax::Work] model the model backing the form
      # @param [Ability] current_ability the user authorization model
      # @param [Array<String>] batch_document_ids a list of document ids in the batch
      def initialize(model, _current_ability, batch_document_ids)
        @names = []
        @batch_document_ids = batch_document_ids
        if @batch_document_ids.present?
          combined_fields = model_attributes(model, initialize_combined_fields)
          super(resource: model.class.new(combined_fields))
        else
          super(resource: model)
        end
      end

      attr_reader :batch_document_ids

      # Returns a list of parameters we accept from the form
      def self.build_permitted_params
        terms_permitted_params + additional_permitted_params
      end

      # Returns a list of parameters other than those terms for the form
      # rubocop:disable Metrics/MethodLength
      def self.additional_permitted_params
        [{ permissions_attributes: [:type, :name, :access, :id, :_destroy] },
         :on_behalf_of,
         :version,
         :add_works_to_collection,
         :visibility_during_embargo,
         :embargo_release_date,
         :visibility_after_embargo,
         :visibility_during_lease,
         :lease_expiration_date,
         :visibility_after_lease,
         :visibility,
         { based_near_attributes: [:id, :_destroy] }]
      end
      # rubocop:enable Metrics/MethodLength

      # Returns a list of permitted parameters for the terms
      # @param terms Array[Symbol]
      # @return Array[Hash]
      def self.terms_permitted_params
        [].tap do |params|
          terms.each do |term|
            h = {}
            h[term] = []
            params << h
          end
        end
      end

      # @param name [Symbol]
      # @return [Symbol]
      # @note Added for ActiveModel compatibility.
      def column_for_attribute(name)
        name
      end

      private

      # override this method if you need to initialize more complex RDF assertions (b-nodes)
      # @return [Hash<String, Array>] the list of unique values per field
      def initialize_combined_fields
        # For each of the files in the batch, set the attributes to be the concatenation of all the attributes
        batch_document_ids.each_with_object({}) do |doc_id, combined_attributes|
          work = Hyrax.query_service.find_by(id: doc_id)
          self.class.terms.each do |field|
            combined_attributes[field] ||= []
            combined_attributes[field] = (combined_attributes[field] + Array.wrap(work[field])).uniq
          end
          names << work.to_s
        end
      end

      # Model attributes for ActiveFedora compatibility
      def model_attributes(model, attrs)
        return attrs unless model.is_a? ActiveFedora::Base

        attrs.keys.each do |k|
          attrs[k] = Array.wrap(attrs[k]).first unless model.class.properties[k.to_s]&.multiple?
        end
        attrs
      end
    end
  end
end
