# frozen_string_literal: true
module Hyrax
  module Fixity
    ##
    # Wraps `ActiveFedora::FixityService` to avoid leaking Fedora-specific errors.
    #
    # @see ActiveFedora::FixityService
    class ActiveFedoraFixityService < ActiveFedora::FixityService
      ##
      # @raise MissingContentError
      # @see ActiveFedora::FixityService#response
      def response
        super
      rescue Ldp::NotFound
        raise MissingContentError,
              "Tried to check fixity of #{@target}, but it was not found."
      end
    end
  end
end
