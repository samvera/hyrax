module Hyrax
  module Forms
    module Admin
      class CollectionTypeParticipantForm
        include ActiveModel::Model
        attr_accessor :collection_type_participant
        validates :agent_id, presence: true
        validates :agent_type, presence: true
        validates :access, presence: true
        validates :hyrax_collection_type_id, presence: true

        delegate :agent_id, :agent_type, :access, :hyrax_collection_type_id, to: :collection_type_participant
      end
    end
  end
end
