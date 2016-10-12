require 'curation_concerns/callbacks'

module CurationConcerns
  class << self
    attr_accessor :config
  end

  def self.configure
    self.config ||= Configuration.new
    yield(config)
  end

  class Configuration
    include Callbacks

    def initialize
      @registered_concerns = []
    end

    # An anonymous function that receives a path to a file
    # and returns AntiVirusScanner::NO_VIRUS_FOUND_RETURN_VALUE if no
    # virus is found; Any other returned value means a virus was found
    attr_writer :default_antivirus_instance
    def default_antivirus_instance
      @default_antivirus_instance ||= lambda do |_file_path|
        AntiVirusScanner::NO_VIRUS_FOUND_RETURN_VALUE
      end
    end

    # Path on the local file system where derivatives will be stored
    attr_writer :derivatives_path
    def derivatives_path
      @derivatives_path ||= File.join(Rails.root, 'tmp', 'derivatives')
    end

    # Path on the local file system where originals will be staged before being ingested into Fedora.
    attr_writer :working_path
    def working_path
      @working_path ||= File.join(Rails.root, 'tmp', 'uploads')
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

    attr_accessor :temp_file_base, :enable_local_ingest,
                  :analytics, :analytic_start_date

    attr_writer :display_microdata
    def display_microdata
      return @display_microdata unless @display_microdata.nil?
      @display_microdata = true
    end

    attr_writer :microdata_default_type
    def microdata_default_type
      @microdata_default_type ||= 'http://schema.org/CreativeWork'
    end

    attr_writer :max_days_between_audits
    def max_days_between_audits
      @max_days_between_audits ||= 7
    end

    attr_writer :enable_noids
    def enable_noids
      return @enable_noids unless @enable_noids.nil?
      @enable_noids = true
    end

    attr_writer :translate_uri_to_id
    def translate_uri_to_id
      @translate_uri_to_id ||= ActiveFedora::Noid.config.translate_uri_to_id
    end

    attr_writer :translate_id_to_uri
    def translate_id_to_uri
      @translate_id_to_uri ||= ActiveFedora::Noid.config.translate_id_to_uri
    end

    attr_writer :noid_template
    def noid_template
      @noid_template ||= '.reeddeeddk'
    end

    attr_writer :minter_statefile
    def minter_statefile
      @minter_statefile ||= '/tmp/minter-state'
    end

    attr_writer :display_media_download_link
    def display_media_download_link
      return @display_media_download_link unless @display_media_download_link.nil?
      @display_media_download_link = true
    end

    attr_writer :fits_path
    def fits_path
      @fits_path ||= 'fits.sh'
    end

    # Override characterization runner
    attr_accessor :characterization_runner

    # Attributes for the lock manager which ensures a single process/thread is mutating a ore:Aggregation at once.
    # @!attribute [w] lock_retry_count
    #   How many times to retry to acquire the lock before raising UnableToAcquireLockError
    attr_writer :lock_retry_count
    def lock_retry_count
      @lock_retry_count ||= 600 # Up to 2 minutes of trying at intervals up to 200ms
    end

    # @!attribute [w] lock_time_to_live
    #   How long to hold the lock in milliseconds
    attr_writer :lock_time_to_live
    def lock_time_to_live
      @lock_time_to_live ||= 60_000 # milliseconds
    end

    # @!attribute [w] lock_retry_delay
    #   Maximum wait time in milliseconds before retrying. Wait time is a random value between 0 and retry_delay.
    attr_writer :lock_retry_delay
    def lock_retry_delay
      @lock_retry_delay ||= 200 # milliseconds
    end

    # @!attribute [w] ingest_queue_name
    #   ActiveJob queue to handle ingest-like jobs.
    attr_writer :ingest_queue_name
    def ingest_queue_name
      @ingest_queue_name ||= :default
    end

    # @!attribute [w] import_export_jar_file_path
    #   Path to the jar file for the Fedora import/export tool
    attr_writer :import_export_jar_file_path
    def import_export_jar_file_path
      @import_export_jar_file_path ||= "tmp/fcrepo-import-export.jar"
    end

    # @!attribute [w] descriptions_directory
    #   Location where description files are exported
    attr_writer :descriptions_directory
    def descriptions_directory
      @descriptions_directory ||= "tmp/descriptions"
    end

    # @!attribute [w] binaries_directory
    #   Location where binary files are exported
    attr_writer :binaries_directory
    def binaries_directory
      @binaries_directory ||= "tmp/binaries"
    end

    # @!attribute [w] dashboard_configuration
    #   Configuration for dashboard rendering.
    attr_writer :dashboard_configuration
    def dashboard_configuration
      @dashboard_configuration ||= {
        menu: {
          index: {},
          resource_details: {}
        },
        actions: {
          index: {
            partials: [
              "total_objects_charts",
              "total_embargo_visibility"
            ]
          },
          resource_details: {
            partials: [
              "total_objects"
            ]
          }
        },
        data_sources: {
          resource_stats: CurationConcerns::ResourceStatisticsSource
        }
      }
    end

    callback.enable :after_create_concern, :after_create_fileset,
                    :after_update_content, :after_revert_content,
                    :after_update_metadata, :after_import_local_file_success,
                    :after_import_local_file_failure, :after_audit_failure,
                    :after_destroy, :after_import_url_success,
                    :after_import_url_failure

    # Registers the given curation concern model in the configuration
    # @param [Array<Symbol>,Symbol] curation_concern_types
    def register_curation_concern(*curation_concern_types)
      Array.wrap(curation_concern_types).flatten.compact.each do |cc_type|
        unless @registered_concerns.include?(cc_type)
          @registered_concerns << cc_type
        end
      end
    end

    # The normalization done by this method must occur after the initialization process
    # so it can take advantage of irregular inflections from config/initializers/inflections.rb
    # @return [Array<String>] the class names of the registered curation concerns
    def registered_curation_concern_types
      @registered_concerns.map { |cc_type| normalize_concern_name(cc_type) }
    end

    # @return [Array<Class>] the registered curation concerns
    def curation_concerns
      registered_curation_concern_types.map(&:constantize)
    end

    # A configuration point for changing the behavior of the license service.
    #
    # @!attribute [w] license_service_class
    #   A configuration point for changing the behavior of the license service.
    #
    #   @see CurationConcerns::LicenseService for implementation details
    #   @see https://github.com/projecthydra/curation_concerns/pull/1047
    attr_writer :license_service_class
    def license_service_class
      @license_service_class ||= CurationConcerns::LicenseService
    end

    private

      # @param [Symbol] the symbol representing the model
      # @return [String] the class name for the model
      def normalize_concern_name(c)
        c.to_s.camelize
      end
  end

  configure {}
end
