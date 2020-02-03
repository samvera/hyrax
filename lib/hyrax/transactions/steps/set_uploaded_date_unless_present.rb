# frozen_string_literal: true
module Hyrax
  module Transactions
    module Steps
      ##
      # A step that sets the uploaded date for an input `Valkyrie::Resource` or
      # `ValkyrieChangeSet`.
      #
      # The uploaded date is derived in the following way:
      #
      #   - if a `date_uploaded` is already present, keep it;
      #   - if there is no current `date_uploaded` but `date_modified` is
      #     present, use the value of `date_modified`.
      #   - if neither `date_uploaded` nor `date_modified` is present, set the
      #     time to now using the given `time_service`. `Hyrax::TimeService`
      #     is used by default.
      #
      # A useful pattern is to run this step immediately following one to set
      # the `date_modified` to now, and just before validation and save. This
      # pattern ensures the times for a newly created object have the same
      # value as close to the actual save time as practicable, and avoids
      # overwriting `date_uploaded` for existing objects.
      #
      # @since 3.0.0
      class SetUploadedDateUnlessPresent
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
