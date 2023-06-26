# frozen_string_literal: true
module Hyrax
  module Actors
    # Creates a work and attaches files to the work
    class CreateWithFilesActor < Hyrax::Actors::AbstractActor
      # @param [Hyrax::Actors::Environment] env
      # @return [Boolean] true if create was successful
      def create(env)
        uploaded_file_ids = filter_file_ids(env.attributes.delete(:uploaded_files))
        files             = uploaded_files(uploaded_file_ids)
        # get a current copy of attributes, to protect against future mutations
        attributes        = env.attributes.clone

        validate_files(files, env) &&
          next_actor.create(env) &&
          attach_files(files, env.curation_concern, attributes)
      end

      # @param [Hyrax::Actors::Environment] env
      # @return [Boolean] true if update was successful
      def update(env)
        uploaded_file_ids = filter_file_ids(env.attributes.delete(:uploaded_files))
        files             = uploaded_files(uploaded_file_ids)
        # get a current copy of attributes, to protect against future mutations
        attributes        = env.attributes.clone

        validate_files(files, env) &&
          next_actor.update(env) &&
          attach_files(files, env.curation_concern, attributes)
      end

      private

      def filter_file_ids(input)
        Array.wrap(input).select(&:present?)
      end

      # ensure that the files we are given are owned by the depositor of the work
      def validate_files(files, env)
        expected_user_id = env.user.id
        files.each do |file|
          if file.user_id != expected_user_id
            Hyrax.logger.error "User #{env.user.user_key} attempted to ingest uploaded_file #{file.id}, but it belongs to a different user"
            return false
          end
        end
        true
      end

      # @return [TrueClass]
      def attach_files(files, curation_concern, attributes)
        return true if files.blank?
        AttachFilesToWorkJob.perform_later(curation_concern, files, **attributes.to_h.symbolize_keys)
        true
      end

      # Fetch uploaded_files from the database
      def uploaded_files(uploaded_file_ids)
        return [] if uploaded_file_ids.empty?
        UploadedFile.find(uploaded_file_ids)
      end
    end
  end
end
