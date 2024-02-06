# frozen_string_literal: true
module Goddess
  class CustomQueryContainer < Valkyrie::Persistence::CustomQueryContainer
    ##
    # @note What do we do when we have an empty array returned in the first query service?
    def method_missing(method_name, *args, **opts)
      # As we iterate through the services, we need to know if any of them responded to the given
      # method_name.
      service_responds_to = false
      returning_value = nil
      exception = nil

      query_service.services.each do |service|
        next unless service.custom_queries.respond_to?(method_name)
        service_responds_to = true
        returning_value = service.custom_queries.send(method_name, *args, **opts)
        # Note, an empty array is "true" in this case.  Should it be?
        break if returning_value

        # If we don't find the resource in the first service, we should try again in the second
        # service, and so forth
        rescue Valkyrie::Persistence::ObjectNotFoundError => e
          exception = e
          next
      end

      # None of the services responded to the method_name
      return super unless service_responds_to

      # At least one of the services had a valid query result; though it could be an empty array.
      # Is that okay?  What if we would have had a non-empty array in a later service?
      return returning_value if returning_value

      raise exception
    end

    def respond_to_missing?(method_name, _include_private = false)
      query_service.services.each do |service|
        return true if service.custom_queries.respond_to?(method_name)
      end

      super
    end
  end
end
