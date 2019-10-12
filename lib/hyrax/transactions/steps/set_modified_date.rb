# frozen_string_literal: true
module Hyrax
  module Transactions
    module Steps
      ##
      # A step that sets the modified date to now for an input resource or
      # change_set
      #
      # @since 2.4.0
      class SetModifiedDate
        include Dry::Monads[:result]

        ##
        # @param [#time_in_utc] time_service
        def initialize(time_service: Hyrax::TimeService)
          @time_service = time_service
        end

        ##
        # @param [#date_modified=] obj
        #
        # @return [Dry::Monads::Result]
        def call(obj)
          return Failure[:no_date_modified_attribute, obj] unless
            obj.respond_to?(:date_modified=)

          obj.date_modified = @time_service.time_in_utc

          Success(obj)
        end
      end
    end
  end
end
