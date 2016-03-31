module CurationConcerns
  # The CurationConcern base actor responds to two primary actions:
  # * #create
  # * #update
  # it must instantiate the next actor in the chain and instantiate it.
  # it should respond to curation_concern, user and attributes.
  class BaseActor < AbstractActor
    attr_reader :cloud_resources

    def initialize(curation_concern, user, attributes, more_actors)
      @cloud_resources = attributes.delete(:cloud_resources.to_s)
      super
    end

    def create
      apply_creation_data_to_curation_concern
      apply_save_data_to_curation_concern
      next_actor.create && save
    end

    def update
      apply_update_data_to_curation_concern
      apply_save_data_to_curation_concern
      next_actor.update && save
    end

    protected

      def apply_creation_data_to_curation_concern
        apply_depositor_metadata
        apply_deposit_date
      end

      def apply_update_data_to_curation_concern
        true
      end

      def apply_depositor_metadata
        curation_concern.apply_depositor_metadata(user.user_key)
        curation_concern.edit_users += [user.user_key]
      end

      def apply_deposit_date
        curation_concern.date_uploaded = CurationConcerns::TimeService.time_in_utc
      end

      def save
        curation_concern.save
      end

      def apply_save_data_to_curation_concern
        attributes[:rights] = Array(attributes[:rights]) if attributes.key? :rights
        remove_blank_attributes!
        curation_concern.attributes = attributes.symbolize_keys
        curation_concern.date_modified = CurationConcerns::TimeService.time_in_utc
      end

      # If any attributes are blank remove them
      # e.g.:
      #   self.attributes = { 'title' => ['first', 'second', ''] }
      #   remove_blank_attributes!
      #   self.attributes
      # => { 'title' => ['first', 'second'] }
      def remove_blank_attributes!
        multivalued_form_attributes.each_with_object(attributes) do |(k, v), h|
          h[k] = v.instance_of?(Array) ? v.select(&:present?) : v
        end
      end

      # Return the hash of attributes that are multivalued and not uploaded files
      def multivalued_form_attributes
        attributes.select { |_, v| v.respond_to?(:select) && !v.respond_to?(:read) }
      end
  end
end
