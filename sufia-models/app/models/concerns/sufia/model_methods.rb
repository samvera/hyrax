module Sufia
  module ModelMethods
    extend ActiveSupport::Concern

    included do
      include Hydra::ModelMethods
    end

    # OVERRIDE to support Hydra::Datastream::Properties which does not
    #   respond to :depositor_values but :depositor
    # Adds metadata about the depositor to the asset
    # Most important behavior: if the asset has a rightsMetadata datastream, this method will add +depositor_id+ to its individual edit permissions.

    def apply_depositor_metadata(depositor)
      rights_ds = self.datastreams["rightsMetadata"]
      prop_ds = self.datastreams["properties"]
      depositor_id = depositor.respond_to?(:user_key) ? depositor.user_key : depositor

      rights_ds.update_indexed_attributes([:edit_access, :person]=>depositor_id) unless rights_ds.nil?
      prop_ds.depositor = depositor_id unless prop_ds.nil?

      return true
    end

    def to_s
      return Array(title).join(" | ") if title.present?
      label || "No Title"
    end

  end
end
