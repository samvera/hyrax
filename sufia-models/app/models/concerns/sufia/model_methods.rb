module Sufia
  module ModelMethods
    extend ActiveSupport::Concern

    included do
      include Hydra::ModelMethods
    end

    # OVERRIDE to support Hydra::Datastream::Properties which does not
    #   respond to :depositor_values but :depositor
    # Adds metadata about the depositor to the asset and ads +depositor_id+ to
    # its individual edit permissions.
    def apply_depositor_metadata(depositor)
      depositor_id = depositor.respond_to?(:user_key) ? depositor.user_key : depositor

      self.edit_users += [depositor_id]
      self.depositor = depositor_id

      return true
    end

    def to_s
      if title.present?
        Array(title).join(" | ")
      elsif label.present?
        Array(label).join(" | ")
      else
        "No Title"
      end
    end

  end
end
