# frozen_string_literal: true
require 'dry/monads'

module Hyrax
  module Transactions
    module Steps
      ##
      # Add a given `::User` as the `#creator` via a ChangeSet.
      #
      # If no user is given, simply passes as a `Success`.
      #
      # @since 3.0.0
      class SetUserAsCreator
        include Dry::Monads[:result]

        ##
        # @param [Hyrax::ChangeSet] change_set
        # @param [#user_key] user
        #
        # @return [Dry::Monads::Result]
        def call(change_set, user: NullUser.new)
          change_set.creator = [user.user_key] if user.user_key

          Success(change_set)
        rescue NoMethodError => err
          Failure.new([err.message, change_set], err.backtrace.first)
        end

        ##
        # @api private
        class NullUser
          ##
          # @return [nil]
          def user_key
            nil
          end
        end
      end
    end
  end
end
