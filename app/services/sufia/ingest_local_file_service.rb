module Sufia
  class IngestLocalFileService
    attr_reader :current_user, :logger
    attr_accessor :files

    def initialize(current_user, logger = nil)
      @current_user = current_user
      @logger = logger
    end

    def ingest_local_file(local_files, parent_id, upload_set_id)
      # Ingest files already on disk
      @files = []
      local_files.each do |filename|
        if File.directory?(File.join(current_user.directory, filename))
          add_files_in_directory(filename)
        else
          files << filename
        end
      end
      UploadSet.find_or_create(upload_set_id) unless files.empty?
      parent = ActiveFedora::Base.find(parent_id)
      files.each do |filename|
        ingest_one(filename, upload_set_id, parent)
      end
      true
    end

    private

      def add_files_in_directory(filename)
        Dir[File.join(current_user.directory, filename, '**', '*')].each do |single|
          next if File.directory? single
          logger.info("Ingesting file: #{single}") if logger
          files << single.sub(current_user.directory + '/', '')
          logger.info("after removing the user directory #{current_user.directory} we have: #{files.last}") if logger
        end
      end

      def ingest_one(filename, upload_set_id, parent)
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
  end
end
