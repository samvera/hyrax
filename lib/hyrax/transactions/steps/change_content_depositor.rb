# frozen_string_literal: true
require 'dry/monads'

module Hyrax
  module Transactions
    module Steps
      ##
      # Add a given `::User` as the `#depositor`
      # Move the previous value of that property to `#proxy_depositor`
      #
      #
      # If no user is given, simply passes as a `Success`.
      #
      # @since 3.4.0
      class ChangeContentDepositor
        include Dry::Monads[:result]

        ##
        # @param [Hyrax::Work] obj
        # @param user [User] the user that will "become" the depositor of
        #             the given work
        #
        # @return [Dry::Monads::Result]
        def call(obj, user: NullUser.new, reset: false)
          obj = Hyrax::ChangeContentDepositorService.call(obj, user, reset)

          Success(obj)
        rescue StandardError => err
          Failure([err.message, obj])
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
