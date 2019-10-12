# frozen_string_literal: true
require 'dry/monads'

module Hyrax
  module Transactions
    module Steps
      ##
      # Saves a given work, returning a Result (Success|Failure)
      class Save
        include Dry::Monads[:result]

        ##
        # @params [#save] persister
        def initialize(persister: Hyrax.persister)
          @persister = persister
        end

        ##
        # @param [Hyrax::ChangeSet] change_set
        #
        # @return [Dry::Monads::Result] `Success(work)` if the change_set is
        #   applied and the resource is saved;
        #   `Failure([#to_s, change_set.resource])`, otherwise.
        def call(change_set)
          change_set.sync

          Success(@persister.save(resource: change_set.resource))
        rescue StandardError => err
          Failure([err.message, change_set.resource])
        end
      end
    end
  end
end
