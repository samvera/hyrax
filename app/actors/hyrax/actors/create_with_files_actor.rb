module Hyrax
  module Actors
    # Creates a work and attaches files to the work
    class CreateWithFilesActor < Hyrax::Actors::AbstractActor
      # @param [Hyrax::Actors::Environment] env
      # @return [Valkyrie::Resource,FalseClass] the saved resource if create was successful
      def create(env)
        uploaded_file_ids = filter_file_ids(env.attributes.delete(:uploaded_files))
        files = uploaded_files(uploaded_file_ids)
        return false unless validate_files(files, env)
        saved = next_actor.create(env)
        return saved if saved && attach_files(files, env)
        false
      end

      # @param [Hyrax::Actors::Environment] env
      # @return [Valkyrie::Resource,FalseClass] the saved resource if update was successful
      def update(env)
        uploaded_file_ids = filter_file_ids(env.attributes.delete(:uploaded_files))
        files = uploaded_files(uploaded_file_ids)
        return false unless validate_files(files, env)
        saved = next_actor.update(env)
        return saved if saved && attach_files(files, env)
        false
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
              Rails.logger.error "User #{env.user.user_key} attempted to ingest uploaded_file #{file.id}, but it belongs to a different user"
              return false
            end
          end
          true
        end

        # @return [TrueClass]
        def attach_files(files, env)
          return true if files.blank?
          AttachFilesToWorkJob.perform_later(env.curation_concern, files, env.attributes.to_h.symbolize_keys)
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
