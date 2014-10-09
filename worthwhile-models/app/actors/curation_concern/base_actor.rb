
module CurationConcern
  # The CurationConcern base actor should respond to three primary actions:
  # * #create
  # * #update
  # * #delete
  class BaseActor
    attr_reader :curation_concern, :user, :attributes, :cloud_resources
    def initialize(curation_concern, user, input_attributes)
      @curation_concern = curation_concern
      @user = user
      @attributes = input_attributes.dup.with_indifferent_access
      @visibility = attributes[:visibility]
      @cloud_resources= attributes.delete(:cloud_resources.to_s)
    end

    attr_reader :visibility
    protected :visibility

    delegate :visibility_changed?, to: :curation_concern

    def create
      apply_creation_data_to_curation_concern
      apply_save_data_to_curation_concern
      save
    end

    def update
      apply_update_data_to_curation_concern
      apply_save_data_to_curation_concern
      save
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
      curation_concern.date_uploaded = Date.today
    end

    def save
      curation_concern.save
    end

    def apply_save_data_to_curation_concern
      attributes[:rights] = Array(attributes[:rights]) if attributes.key? :rights
      remove_blank_attributes!
      curation_concern.attributes = attributes
      curation_concern.date_modified = Date.today
    end

    def attach_file(generic_file, file_to_attach)
      ActiveSupport::Deprecation.warn("removing #{self.class}#attach_file, use CurationConcern.attach_file instead")
      CurationConcern.attach_file(generic_file, user, file_to_attach)
    end

    # If any attributes are blank remove them
    # e.g.:
    #   self.attributes = { 'title' => ['first', 'second', ''] }
    #   remove_blank_attributes!
    #   self.attributes
    # => { 'title' => ['first', 'second'] }
    def remove_blank_attributes!
      multivalued_form_attributes.each_with_object(attributes) do |(k, v), h|
        h[k] = v.select(&:present?)
      end
    end

    # Return the hash of attributes that are multivalued and not uploaded files
    def multivalued_form_attributes
      attributes.select {|_, v| v.respond_to?(:select) && !v.respond_to?(:read) }
    end
  end
end
