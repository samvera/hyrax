module Sufia
  module FilesController::LocalIngestBehavior
    include ActiveSupport::Concern

    def create
      file_set_attributes = params.fetch(:file_set)
      if file_set_attributes[:local_file].present?
        upload_set_id = params.fetch(:upload_set_id)
        perform_local_ingest(file_set_attributes, params.fetch(:parent_id), upload_set_id)
      else
        super
      end
    end

    private

      def perform_local_ingest(file_set_attributes, parent_id, upload_set_id)
        if Sufia.config.enable_local_ingest && current_user.respond_to?(:directory)
          local_files = file_set_attributes.fetch(:local_file)
          if ingest_local_file(local_files, parent_id, upload_set_id)
            redirect_to CurationConcerns::FileSetsController.upload_complete_path(upload_set_id)
          else
            flash[:alert] = "Error importing files from user directory."
            render :new
          end
        else
          flash[:alert] = "Your account is not configured for importing files from a user-directory on the server."
          render :new
        end
      end

      # TODO: this method should be extracted to a service class
      def ingest_local_file(local_files, parent_id, upload_set_id)
        # Ingest files already on disk
        has_directories = false
        files = []
        local_files.each do |filename|
          if File.directory?(File.join(current_user.directory, filename))
            has_directories = true
            Dir[File.join(current_user.directory, filename, '**', '*')].each do |single|
              next if File.directory? single
              logger.info("Ingesting file: #{single}")
              files << single.sub(current_user.directory + '/', '')
              logger.info("after removing the user directory #{current_user.directory} we have: #{files.last}")
            end
          else
            files << filename
          end
        end
        UploadSet.find_or_create(upload_set_id) unless files.empty?
        parent = ActiveFedora::Base.find(parent_id)
        files.each do |filename|
          ingest_one(filename, upload_set_id, parent, has_directories)
        end
        true
      end

      def ingest_one(filename, upload_set_id, parent, _unarranged)
        basename = File.basename(filename)
        # do not remove ::
        ::FileSet.new(label: basename).tap do |fs|
          fs.relative_path = filename if filename != basename
          actor = CurationConcerns::FileSetActor.new(fs, current_user)
          actor.create_metadata(upload_set_id, parent)
          fs.save!
          IngestLocalFileJob.perform_later(fs.id, current_user.directory, filename, current_user.user_key)
        end
      end
  end # /FilesController::LocalIngestBehavior
end # /Sufia
