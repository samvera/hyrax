module Hyrax
  module Noid
    extend ActiveSupport::Concern

    ## This overrides the default behavior, which is to ask Fedora for an id
    # @see ActiveFedora::Persistence.assign_id
    def assign_id
      service.mint if Hyrax.config.enable_noids?
    end

    ##
    # Mints ids until one of them isn't in use in the Fedora backend
    #
    # @note this uses up an identifier from the minter which won't ever be
    #   assigned to an object
    #
    # @return [Boolean] true if we have successfully re-established a valid
    #   minter state
    def ensure_valid_minter_state
      return true unless Hyrax.config.enable_noids?

      loop { break unless ActiveFedora::Base.exists?(service.mint) }

      true
    end

    private

      def service
        @service ||= ::Noid::Rails::Service.new
      end
  end
end
