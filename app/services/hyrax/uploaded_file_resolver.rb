# frozen_string_literal: true

module Hyrax
  ##
  # @api public
  #
  # The single seam turning staged-upload id params into
  # {Hyrax::UploadedFile} records, enforcing that the acting user owns every
  # file being attached.
  #
  # The non-ActiveFedora attach paths (work create/update, file set version
  # upload, collection branding) resolve their uploaded file params through
  # this service. The ActiveFedora actor stack performs its equivalent check
  # in {Hyrax::Actors::CreateWithFilesActor}.
  #
  # @example
  #   Hyrax::UploadedFileResolver.call(params[:uploaded_files], user: current_user)
  class UploadedFileResolver
    ##
    # Raised when staged uploads are attached by a user other than their
    # owner. Rescued at the controller edge by
    # {Hyrax::EnforcesStagedUploadOwnership}.
    class OwnershipError < RuntimeError
      def initialize(msg = "attempted to attach uploaded files owned by another user")
        super
      end
    end

    ##
    # @param ids [Enumerable<String, Integer>, String, Integer, nil]
    #   staged upload ids, as they arrive in params
    # @param user [::User] the acting user
    #
    # @return [Array<Hyrax::UploadedFile>] the resolved files, in id order
    #
    # @raise [ActiveRecord::RecordNotFound] when an id does not exist
    # @raise [OwnershipError] when a file belongs to another user
    def self.call(ids, user:)
      ids = Array.wrap(ids).select(&:present?)
      return [] if ids.empty?

      files = Array.wrap(Hyrax::UploadedFile.find(ids))
      foreign = files.reject { |file| file.user_id == user&.id }

      foreign.each do |file|
        Hyrax.logger.error "User #{user.try(:user_key)} attempted to ingest uploaded_file #{file.id}, " \
                           "but it belongs to a different user"
      end
      raise OwnershipError unless foreign.empty?

      files
    end
  end
end
