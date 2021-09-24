# frozen_string_literal: true
require 'dry/monads'

module Hyrax
  module Transactions
    module Steps
      ##
      # Add a given `::User` as an `#editor` via a ChangeSet.
      #
      # If no user is given, simply passes as a `Success`.
      #
      # @since 3.0.0
      class SetUserAsEditor
        include Dry::Monads[:result]

        ##
        # @param [Hyrax::Resource] obj
        # @param [#user_key] user
        #
        # @return [Dry::Monads::Result]
        def call(obj, user:)
          # ignore empty user
          return Success(obj) if user&.user_key.blank?
          obj.permission_manager.edit_users += [user.user_key]

          Success(obj)
        rescue NoMethodError => err
          Failure([err.message, obj])
        end
      end
    end
  end
end
