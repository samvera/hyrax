# frozen_string_literal: true
require 'dry/monads'

module Hyrax
  module Transactions
    module Steps
      ##
      # Adds a work to a parent work
      #
      # @see https://wiki.lyrasis.org/display/samvera/Hydra::Works+Shared+Modeling
      class AddToParent
        include Dry::Monads[:result]

        ##
        # @param [Hyrax::Work] obj
        # @param [#to_s] parent_id
        #
        # @return [Dry::Monads::Result]
        def call(obj, parent_id: nil)
          return Success(obj) if parent_id.blank?

          parent = Hyrax.query_service.find_by(id: parent_id)
          parent.member_ids << obj.id
          Hyrax.persister.save(resource: parent)

          Success(obj)
        rescue Valkyrie::Persistence::ObjectNotFoundError => _err
          Failure[:parent_object_not_found, parent_id]
        end
      end
    end
  end
end
