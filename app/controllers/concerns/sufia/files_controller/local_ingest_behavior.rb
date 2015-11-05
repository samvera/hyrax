module Sufia
  module FilesController::LocalIngestBehavior
    include ActiveSupport::Concern

    def create
      if params[:local_file].present?
        perform_local_ingest
      else
        super
      end
    end

    private

      def perform_local_ingest
        if Sufia.config.enable_local_ingest && current_user.respond_to?(:directory)
          if ingest_local_file
            redirect_to FileSetsController.upload_complete_path(params[:upload_set_id])
          else
            flash[:alert] = "Error importing files from user directory."
            render :new
          end
        else
          flash[:alert] = "Your account is not configured for importing files from a user-directory on the server."
          render :new
        end
      end

      def ingest_local_file
        # Ingest files already on disk
        has_directories = false
        files = []
        params[:local_file].each do |filename|
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
        UploadSet.find_or_create(params[:upload_set_id]) unless files.empty?
        files.each do |filename|
          ingest_one(filename, has_directories)
        end
        true
      end

      def ingest_one(filename, _unarranged)
        basename = File.basename(filename)
        # do not remove ::
        ::FileSet.new(label: basename).tap do |fs|
          fs.relative_path = filename if filename != basename
          actor = CurationConcerns::FileSetActor.new(fs, current_user)
          actor.create_metadata(params[:upload_set_id], params[:parent_id])
          fs.save!
          IngestLocalFileJob.perform_later(fs.id, current_user.directory, filename, current_user.user_key)
        end
      end
  end # /FilesController::LocalIngestBehavior
end # /Sufia
