module CurationConcerns
  class << self
    attr_accessor :configuration
  end

  def self.configure
    self.configuration ||= Configuration.new
    yield(configuration)
  end

  class Configuration
    # An anonymous function that receives a path to a file
    # and returns AntiVirusScanner::NO_VIRUS_FOUND_RETURN_VALUE if no
    # virus is found; Any other returned value means a virus was found
    attr_writer :default_antivirus_instance
    def default_antivirus_instance
      @default_antivirus_instance ||= lambda do|_file_path|
        AntiVirusScanner::NO_VIRUS_FOUND_RETURN_VALUE
      end
    end

    # Configure default search options from config/search_config.yml
    attr_writer :search_config
    def search_config
      @search_config ||= 'search_config not set'
    end

    # Configure the application root url.
    attr_writer :application_root_url
    def application_root_url
      @application_root_url || (fail 'Make sure to set your CurationConcerns.configuration.application_root_url')
    end

    # When was this last built/deployed
    attr_writer :build_identifier
    def build_identifier
      # If you restart the server, this could be out of sync; A better
      # implementation is to read something from the file system. However
      # that detail is an exercise for the developer.
      @build_identifier ||= Time.now.strftime('%Y-%m-%d %H:%M:%S')
    end

    # Override characterization runner
    attr_accessor :characterization_runner

    def register_curation_concern(*curation_concern_types)
      Array(curation_concern_types).flatten.compact.each do |cc_type|
        class_name = normalize_concern_name(cc_type)
        unless registered_curation_concern_types.include?(class_name)
          registered_curation_concern_types << class_name
        end
      end
    end

    # Returns the class names (strings) of the registered curation concerns
    def registered_curation_concern_types
      @registered_curation_concern_types ||= []
    end

    # Returns the classes of the registered curation concerns
    def curation_concerns
      registered_curation_concern_types.map(&:constantize)
    end

    private

      def normalize_concern_name(c)
        c.to_s.camelize
      end
  end

  configure {}
end
