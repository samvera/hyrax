module Hyrax
  module Actors
    # Actions are decoupled from controller logic so that they may be called from a controller or a background job.
    class FileSetActor
      include Lockable
      attr_reader :file_set, :user, :attributes

      def initialize(file_set, user)
        @file_set = file_set
        @user = user
      end

      # Adds a FileSet to the work.
      # Locks to ensure that only one process is operating on the list at a time.
      def attach_to_work(work, file_set_params = {})
        acquire_lock_for(work.id) do
          # Ensure we have an up-to-date copy of the members association, so that we append to the end of the list.
          work = Hyrax::Queries.find_by(id: work.id) if work.persisted?
          copy_visibility(work.visibility, file_set_params)

          work.member_ids += [file_set.id]
          work.representative_id = file_set.id if work.representative_id.blank?
          work.thumbnail_id = file_set.id if work.thumbnail_id.blank?
          # Save the work so the association between the work and the file_set is persisted (head_id)
          # NOTE: the work may not be valid, in which case this save doesn't do anything.
          persister.save(resource: work)
          # TODO: move this callback into the persister?
          Hyrax.config.callback.run(:after_create_fileset, file_set, user)
        end
      end
      alias attach_file_to_work attach_to_work
      deprecation_deprecate attach_file_to_work: "use attach_to_work instead"

      private

        # Copy visibility to the file set and save it unless it would get set by
        # the form parameters
        def copy_visibility(visibility, file_set_params)
          return if assign_visibility?(file_set_params)
          file_set.visibility = visibility
          persister.save(resource: file_set)
        end

        def persister
          Valkyrie::MetadataAdapter.find(:indexing_persister).persister
        end

        def ability
          @ability ||= ::Ability.new(user)
        end

        # uses create! because object must be persisted to serialize for jobs
        def wrapper!(file:, relation:)
          JobIoWrapper.create_with_varied_file_handling!(user: user, file: file, relation: relation, file_set: file_set)
        end

        # For the label, use the original_filename or original_name if it's there.
        # If the file was imported via URL, parse the original filename.
        # If all else fails, use the basename of the file where it sits.
        # @note This is only useful for labeling the file_set, because of the recourse to import_url
        def label_for(file)
          if file.is_a?(Hyrax::UploadedFile) # filename not present for uncached remote file!
            file.uploader.filename.present? ? file.uploader.filename : File.basename(Addressable::URI.parse(file.file_url).path)
          elsif file.respond_to?(:original_name) # e.g. Hydra::Derivatives::IoDecorator
            file.original_name
          elsif file_set.import_url.present?
            # This path is taken when file is a Tempfile (e.g. from ImportUrlJob)
            File.basename(Addressable::URI.parse(file_set.import_url).path)
          else
            File.basename(file)
          end
        end

        def assign_visibility?(file_set_params = {})
          !((file_set_params || {}).keys.map(&:to_s) & %w[visibility embargo_release_date lease_expiration_date]).empty?
        end

        def unlink_from_work
          work = Hyrax::Queries.find_parents(resource: file_set).first
          return unless work
          work.thumbnail_id = nil if work.thumbnail_id == file_set.id
          work.representative_id = nil if work.representative_id == file_set.id
          work.member_ids.delete(file_set.id)
          persister.save(resource: work)
        end
    end
  end
end
# rubocop:enable Metrics/ClassLength
