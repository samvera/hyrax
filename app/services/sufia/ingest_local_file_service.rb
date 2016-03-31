module Sufia
  class IngestLocalFileService
    attr_reader :current_user, :logger
    attr_accessor :files

    def initialize(current_user, logger = Rails.logger)
      @current_user = current_user
      @logger = logger || CurationConcerns::NullLogger.new
    end

    def ingest_local_file(local_files, parent_id)
      # Ingest files already on disk
      @files = []
      local_files.each do |filename|
        if File.directory?(File.join(current_user.directory, filename))
          add_files_in_directory(filename)
        else
          files << filename
        end
      end
      parent = ActiveFedora::Base.find(parent_id)
      files.each do |filename|
        ingest_one(filename, parent)
      end
      true
    end

    private

      def add_files_in_directory(filename)
        Dir[File.join(current_user.directory, filename, '**', '*')].each do |single|
          next if File.directory? single
          logger.info("Ingesting file: #{single}")
          files << single.sub(current_user.directory + '/', '')
          logger.info("after removing the user directory #{current_user.directory} we have: #{files.last}")
        end
      end

      def ingest_one(filename, parent)
        basename = File.basename(filename)
        # do not remove ::
        ::FileSet.new(label: basename).tap do |fs|
          fs.relative_path = filename if filename != basename
          actor = CurationConcerns::FileSetActor.new(fs, current_user)
          actor.create_metadata(parent)
          fs.save!
          IngestLocalFileJob.perform_later(fs, current_user.directory, filename, current_user)
        end
      end
  end
end
