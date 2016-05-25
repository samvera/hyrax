module CurationConcerns
  module Collection
    extend ActiveSupport::Concern
    include Hydra::WithDepositor # for access to apply_depositor_metadata
    include Hydra::AccessControls::Permissions
    include CurationConcerns::RequiredMetadata
    include Hydra::Works::CollectionBehavior

    def add_members(new_member_ids)
      return if new_member_ids.nil? || new_member_ids.empty?
      members << ActiveFedora::Base.find(new_member_ids)
    end
  end
end
