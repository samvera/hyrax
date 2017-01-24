module Sufia
  module Forms
    class BatchEditForm < Sufia::Forms::WorkForm
      # Used for drawing the fields that appear on the page
      self.terms = [:creator, :contributor, :description,
                    :keyword, :resource_type, :rights, :publisher, :date_created,
                    :subject, :language, :identifier, :based_near,
                    :related_url]
      self.required_fields = []
      self.model_class = Sufia.primary_work_type

      attr_accessor :names

      # @param [ActiveFedora::Base] model the model backing the form
      # @param [Ability] current_ability the user authorization model
      # @param [Array<String>] batch a list of document ids in the batch
      def initialize(model, current_ability, batch)
        super(model, current_ability)
        @names = []
        initialize_combined_fields(batch)
      end

      # Which parameters can we accept from the form
      def self.build_permitted_params
        super + [:visibility_during_embargo, :embargo_release_date,
                 :visibility_after_embargo, :visibility_during_lease,
                 :lease_expiration_date, :visibility_after_lease, :visibility]
      end

      private

        # override this method if you need to initialize more complex RDF assertions (b-nodes)
        # @param [Array<String>] batch a list of document ids in the batch
        def initialize_combined_fields(batch)
          combined_attributes = {}
          permissions = []
          # For each of the files in the batch, set the attributes to be the concatenation of all the attributes
          batch.each do |doc_id|
            work = model_class.find(doc_id)
            terms.each do |key|
              combined_attributes[key] ||= []
              combined_attributes[key] = (combined_attributes[key] + work[key].to_a).uniq
            end
            names << work.to_s
            permissions = (permissions + work.permissions).uniq
          end

          terms.each do |key|
            # if value is empty, we create an one element array to loop over for output
            model[key] = combined_attributes[key].empty? ? [''] : combined_attributes[key]
          end
          model.permissions_attributes = [{ type: 'group', name: 'public', access: 'read' }]
        end
    end
  end
end
