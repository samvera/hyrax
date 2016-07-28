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

    def add_member_objects(new_member_ids)
      Array(new_member_ids).each do |member_id|
        member = ActiveFedora::Base.find(member_id, cast: true)
        member.member_of_collections << self
        member.save!
      end
    end

    def member_objects
      ActiveFedora::Base.where("member_of_collection_ids_ssim:#{id}")
    end
  end
end
