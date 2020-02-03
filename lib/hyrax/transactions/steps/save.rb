# frozen_string_literal: true
require 'dry/monads'

module Hyrax
  module Transactions
    module Steps
      ##
      # Saves a given work from a change_set, returning a `Dry::Monads::Result`
      # (`Success`|`Failure`).
      #
      # If the save is successful, publishes an `object.metadata.updated` event
      # for the affected resource.
      #
      # @see https://dry-rb.org/gems/dry-monads/1.0/result/
      class Save
        include Dry::Monads[:result]

        ##
        # @params [#save] persister
        def initialize(persister: Hyrax.persister)
          @persister = persister
        end

        ##
        # @param [Hyrax::ChangeSet] change_set
        # @param [::User, nil] user
        #
        # @return [Dry::Monads::Result] `Success(work)` if the change_set is
        #   applied and the resource is saved;
        #   `Failure([#to_s, change_set.resource])`, otherwise.
        def call(change_set, user: nil)
          saved = @persister.save(resource: change_set.sync)

          Hyrax.publisher.publish('object.metadata.updated',
                                  object: saved,
                                  user: user)

          Success(saved)
        rescue StandardError => err
          Failure([err.message, change_set.resource])
        end
      end
    end
  end
end
