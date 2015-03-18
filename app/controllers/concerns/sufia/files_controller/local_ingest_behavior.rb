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
          redirect_to GenericFilesController.upload_complete_path( params[:batch_id])
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
      Batch.find_or_create(params[:batch_id]) unless files.empty?
      files.each do |filename|
        ingest_one(filename, has_directories)
      end
      true
    end

    def ingest_one(filename, unarranged)
      basename = File.basename(filename)
      # do not remove ::
      generic_file = ::GenericFile.new(label: basename).tap do |gf|
        gf.relative_path = filename if filename != basename
        actor = Sufia::GenericFile::Actor.new(gf, current_user)
        actor.create_metadata(params[:batch_id])
        gf.save!
        Sufia.queue.push(IngestLocalFileJob.new(gf.id, current_user.directory, filename, current_user.user_key))
      end
    end
  end # /FilesController::LocalIngestBehavior
end # /Sufia
