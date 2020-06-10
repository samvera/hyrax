# frozen_string_literal: true
module Hyrax
  module Forms
    class BatchEditForm < Hyrax::Forms::WorkForm
      # Used for drawing the fields that appear on the page
      self.terms = [:creator, :contributor, :description,
                    :keyword, :resource_type, :license, :publisher, :date_created,
                    :subject, :language, :identifier, :based_near,
                    :related_url]
      self.required_fields = []
      self.model_class = Hyrax.primary_work_type

      # Contains a list of titles of all the works in the batch
      attr_accessor :names

      # @param [ActiveFedora::Base] model the model backing the form
      # @param [Ability] current_ability the user authorization model
      # @param [Array<String>] batch_document_ids a list of document ids in the batch
      def initialize(model, current_ability, batch_document_ids)
        @names = []
        @batch_document_ids = batch_document_ids
        @combined_attributes = initialize_combined_fields
        super(model, current_ability, nil)
      end

      attr_reader :batch_document_ids

      # Returns a list of parameters we accept from the form
      # rubocop:disable Metrics/MethodLength
      def self.build_permitted_params
        [{ creator: [] },
         { contributor: [] },
         { description: [] },
         { keyword: [] },
         { resource_type: [] },
         { license: [] },
         { publisher: [] },
         { date_created: [] },
         { subject: [] },
         { language: [] },
         { identifier: [] },
         { based_near: [] },
         { related_url: [] },
         { permissions_attributes: [:type, :name, :access, :id, :_destroy] },
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

      private

      attr_reader :combined_attributes

      # override this method if you need to initialize more complex RDF assertions (b-nodes)
      # @return [Hash<String, Array>] the list of unique values per field
      def initialize_combined_fields
        # For each of the files in the batch, set the attributes to be the concatenation of all the attributes
        batch_document_ids.each_with_object({}) do |doc_id, combined_attributes|
          work = ActiveFedora::Base.find(doc_id)
          terms.each do |field|
            combined_attributes[field] ||= []
            combined_attributes[field] = (combined_attributes[field] + work[field].to_a).uniq
          end
          names << work.to_s
        end
      end

      def initialize_field(key)
        # if value is empty, we create an one element array to loop over for output
        return model[key] = combined_attributes[key] if combined_attributes[key].present?
        super
      end
    end
  end
end
