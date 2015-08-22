module CurationConcerns
  class << self
    attr_accessor :config
  end

  def self.configure
    self.config ||= Configuration.new
    yield(config)
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
      @application_root_url || (fail 'Make sure to set your CurationConcerns.config.application_root_url')
    end

    # When was this last built/deployed
    attr_writer :build_identifier
    def build_identifier
      # If you restart the server, this could be out of sync; A better
      # implementation is to read something from the file system. However
      # that detail is an exercise for the developer.
      @build_identifier ||= Time.now.strftime('%Y-%m-%d %H:%M:%S')
    end

    # Set some configuration defaults
    attr_writer :persistent_hostpath
    def persistent_hostpath
      @persistent_hostpath ||= 'http://localhost/files/'
    end

    attr_writer :enable_ffmpeg
    def enable_ffmpeg
      return @enable_ffmpeg unless @enable_ffmpeg.nil?
      @enable_ffmpeg = false
    end

    attr_writer :ffmpeg_path
    def ffmpeg_path
      @ffmpeg_path ||= 'ffmpeg'
    end

    attr_writer :fits_message_length
    def fits_message_length
      @fits_message_length ||= 5
    end

    attr_accessor :temp_file_base, :enable_local_ingest, :analytic_start_date,
                  :fits_to_desc_mapping, :max_days_between_audits, :cc_licenses,
                  :cc_licenses_reverse, :resource_types, :resource_types_to_schema,
                  :permission_levels, :owner_permission_levels, :analytics

    attr_writer :enable_noids
    def enable_noids
      return @enable_noids unless @enable_noids.nil?
      @enable_noids = true
    end

    attr_writer :noid_template
    def noid_template
      @noid_template ||= '.reeddeeddk'
    end

    attr_writer :minter_statefile
    def minter_statefile
      @minter_statefile ||= '/tmp/minter-state'
    end

    attr_writer :redis_namespace
    def redis_namespace
      @redis_namespace ||= 'curation_concerns'
    end

    attr_writer :fits_path
    def fits_path
      @fits_path ||= 'fits.sh'
    end

    attr_writer :queue
    def queue
      @queue ||= CurationConcerns::Resque::Queue
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
