module CurationConcerns
  class VirusDetectionService

    # @param [File] file object to check for viruses
    def self.run(file)
      self.detect_viruses(file)
    end

    # @param [File] file object to check for viruses
    def self.detect_viruses(file)
      path = file.is_a?(String) ? file : local_path_for_file(file)
      unless defined?(ClamAV)
        ActiveFedora::Base.logger.warn "Virus checking disabled, #{path} not checked"
        return
      end
      scan_result = ClamAV.instance.scanfile(path)
      raise CurationConcerns::VirusFoundError.new("A virus was found in #{path}: #{scan_result}") unless scan_result == 0
    end

    private

    # Returns a path for reading the content of +file+
    # @param [File] file object to retrieve a path for
    def self.local_path_for_file(file)
      if file.respond_to?(:path)
        file.path
      else
        Tempfile.open('') do |t|
          t.binmode
          t.write(file)
          t.close
          t.path
        end
      end
    end

  end
end
