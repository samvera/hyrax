# frozen_string_literal: true
module Hyrax
  module Transactions
    module Steps
      ##
      # A step that sets the uploaded date to now for an input resource or
      # change_set
      #
      # @since 2.4.0
      class SetUploadedDate
        include Dry::Monads[:result]

        ##
        # @param [#time_in_utc] time_service
        def initialize(time_service: Hyrax::TimeService)
          @time_service = time_service
        end

        ##
        # @note the implementation sets the uploaded date to
        #   `#date_modified` if it exists, falling back on the current datetime.
        #
        # @param [#date_uploaded=] obj
        #
        # @return [Dry::Monads::Result]
        def call(obj)
          return Failure[:no_date_uploaded_attribute, obj] unless
            obj.respond_to?(:date_uploaded=)

          obj.date_uploaded = date_uploaded(obj)

          Success(obj)
        end

        private

          def date_uploaded(obj)
            if obj.try(:date_modified).present?
              obj.try(:date_modified)
            else
              @time_service.time_in_utc
            end
          end
      end
    end
  end
end
