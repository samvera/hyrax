# frozen_string_literal: true
module Goddess
  class CustomQueryContainer < Valkyrie::Persistence::CustomQueryContainer
    ##
    # @!group Class Attributes
    #
    # @!attribute concatenate_results_of_these_queries [r|w]
    #
    #   Some methods need to take the union of entries found in each of the adapters.  As you might
    #   guess this combinatorial banagrams introduces non-performant queries.
    #
    #   As you migrate items out of Fedora, you'll want to consider removing methods from this
    #   array.
    #
    #   @return [Array<Symbol>]
    #
    # @note
    # - :find_ids_by_model is necessary for permissions of {Hyrax::Collections::PermissionsService.filter_source}
    class_attribute :concatenate_results_of_these_queries,
                    default: [
                      :find_parents, # Some parents are old fashioned, and like the old ways.  Let's
                      # at least acknowledge them.
                      :find_ids_by_model # For Hyrax::Collections::PermissionsService.filter_source
                    ]
    # @!endgroup Class Attributes
    ##

    ##
    # @note What do we do when we have an empty array returned in the first query service?
    #
    # rubocop:disable Metrics/MethodLength
    def method_missing(method_name, *args, **opts, &block)
      # method_missing must always and reliably fallback on super.  Without this declaration, we run
      # into stack level too deep errors.
      return super unless query_service.services.detect { |service| service.custom_queries.respond_to?(method_name) }

      if concatenate_results_of_these_queries.include?(method_name)
        dispatch_concatentation_logic(method_name, *args, **opts, &block)
      else
        dispatch_non_concatentation_logic(method_name, *args, **opts, &block)
      end
    end

    def dispatch_concatentation_logic(method_name, *args, **opts, &block)
      # I don't know how we'll handle sums; as we're looking for counts of distinct items.
      query_service.services.flat_map do |service|
        if service.custom_queries.respond_to?(method_name)
          service.custom_queries.public_send(method_name, *args, **opts, &block).to_a
        else
          []
        end
      end.compact.uniq
    end
    private :dispatch_concatentation_logic

    def dispatch_non_concatentation_logic(method_name, *args, **opts, &block)
      # As we iterate through the services, we need to know if any of them responded to the given
      # method_name.
      service_responds_to = false
      returning_value = nil
      exception = nil

      query_service.services.each do |service|
        next unless service.custom_queries.respond_to?(method_name)
        service_responds_to = true
        returning_value = service.custom_queries.public_send(method_name, *args, **opts, &block)
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
    # rubocop:enable Metrics/MethodLength
    private :dispatch_non_concatentation_logic

    def respond_to_missing?(method_name, _include_private = false)
      query_service.services.each do |service|
        return true if service.custom_queries.respond_to?(method_name)
      end

      super
    end
  end
end
