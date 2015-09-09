module CurationConcerns
  extend Deprecation
  class << self
    attr_accessor :config
  end

  def self.configure
    self.config ||= Configuration.new
    yield(config)
  end

  # Keep this deprecated class here so that anyone that references it in their config gets a deprecation rather than uninitialized constant.
  # Remove when Configuration#queue= is removed
  module Resque
    class Queue
    end
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

    # Path on the local file system where derivatives will be stored
    attr_writer :derivatives_path
    def derivatives_path
      @derivatives_path ||= File.join(Rails.root, 'tmp', 'derivatives')
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
                  :fits_to_desc_mapping, :max_days_between_audits,
                  :resource_types, :resource_types_to_schema,
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

    attr_writer :queue
    deprecation_deprecate :queue=

    attr_writer :fits_path
    def fits_path
      @fits_path ||= 'fits.sh'
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
