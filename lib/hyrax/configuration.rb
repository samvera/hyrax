require 'hyrax/callbacks'
require 'hyrax/role_registry'

module Hyrax
  class Configuration
    include Callbacks

    def initialize
      @registered_concerns = []
      @role_registry = Hyrax::RoleRegistry.new
      @default_active_workflow_name = DEFAULT_ACTIVE_WORKFLOW_NAME
    end

    DEFAULT_ACTIVE_WORKFLOW_NAME = 'default'.freeze
    private_constant :DEFAULT_ACTIVE_WORKFLOW_NAME

    # @api public
    # When an admin set is created, we need to activate a workflow.
    # The :default_active_workflow_name is the name of the workflow we will activate.
    #
    # @return [String]
    # @see Sipity::Workflow
    # @see AdminSet
    # @note The active workflow for an admin set can be changed at a later point.
    # @note Changing this value after other AdminSet(s) are created does not alter the already created AdminSet(s)
    attr_accessor :default_active_workflow_name

    # @return [Hyrax::RoleRegistry]
    attr_reader :role_registry
    private :role_registry
    delegate :registered_role?, :persist_registered_roles!, to: :role_registry

    # @api public
    #
    # Exposes a means to register application critical roles
    #
    # @example
    #   Hyrax.config.register_roles do |registry|
    #     registry.add(name: 'captaining', description: 'Grants captain duties')
    #   end
    #
    # @yield [Hyrax::RoleRegistry]
    # @return [TrueClass]
    def register_roles
      yield(@role_registry)
      true
    end

    # Path on the local file system where derivatives will be stored
    attr_writer :derivatives_path
    def derivatives_path
      @derivatives_path ||= Rails.root.join('tmp', 'derivatives')
    end

    # Path on the local file system where originals will be staged before being ingested into Fedora.
    attr_writer :working_path
    def working_path
      @working_path ||= Rails.root.join('tmp', 'uploads')
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

    attr_writer :feature_config_path
    def feature_config_path
      @feature_config_path ||= Rails.root.join('config', 'features.yml')
    end

    attr_accessor :temp_file_base, :enable_local_ingest,
                  :analytics, :analytic_start_date

    attr_writer :display_microdata
    def display_microdata?
      return @display_microdata unless @display_microdata.nil?
      @display_microdata = true
    end
    alias display_microdata display_microdata?
    deprecation_deprecate display_microdata: "use display_microdata? instead"

    attr_writer :microdata_default_type
    def microdata_default_type
      @microdata_default_type ||= 'http://schema.org/CreativeWork'
    end

    attr_writer :max_days_between_audits
    def max_days_between_audits
      @max_days_between_audits ||= 7
    end

    attr_writer :enable_noids
    def enable_noids?
      return @enable_noids unless @enable_noids.nil?
      @enable_noids = true
    end
    alias enable_noids enable_noids?
    deprecation_deprecate enable_noids: "use enable_noids? instead"

    attr_writer :noid_template
    def noid_template
      @noid_template ||= '.reeddeeddk'
    end

    attr_writer :noid_minter_class
    def noid_minter_class
      @noid_minter_class ||= ActiveFedora::Noid::Minter::Db
    end

    attr_writer :minter_statefile
    def minter_statefile
      @minter_statefile ||= '/tmp/minter-state'
    end

    attr_writer :display_media_download_link
    def display_media_download_link?
      return @display_media_download_link unless @display_media_download_link.nil?
      @display_media_download_link = true
    end
    alias display_media_download_link display_media_download_link?
    deprecation_deprecate display_media_download_link: "use display_media_download_link? instead"

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
    # rubocop:disable Metrics/MethodLength
    def dashboard_configuration
      @dashboard_configuration ||= {
        menu: {
          index: {},
          resource_details: {},
          workflow: {},
          workflow_roles: {}
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
          },
          workflow: {
            partials: [
              "workflow"
            ]
          }
        },
        data_sources: {
          resource_stats: Hyrax::ResourceStatisticsSource
        }
      }
    end
    # rubocop:enable Metrics/MethodLength

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
    #   @see Hyrax::LicenseService for implementation details
    attr_writer :license_service_class
    def license_service_class
      @license_service_class ||= Hyrax::LicenseService
    end

    attr_writer :banner_image
    def banner_image
      @banner_image ||= "https://cloud.githubusercontent.com/assets/92044/18370978/88ecac20-75f6-11e6-8399-6536640ef695.jpg"
    end

    attr_writer :persistent_hostpath
    def persistent_hostpath
      @persistent_hostpath ||= "http://localhost/files/"
    end

    attr_writer :redis_namespace
    def redis_namespace
      @redis_namespace ||= "hyrax"
    end

    attr_writer :libreoffice_path
    def libreoffice_path
      @libreoffice_path ||= "soffice"
    end

    attr_writer :browse_everything
    def browse_everything?
      @browse_everything ||= nil
    end
    alias browse_everything browse_everything?
    deprecation_deprecate browse_everything: "use browse_everything? instead"

    attr_writer :analytics
    def analytics?
      @analytics ||= false
    end
    alias analytics analytics?
    deprecation_deprecate analytics: "use analytics? instead"

    attr_writer :citations
    def citations?
      @citations ||= false
    end
    alias citations citations?
    deprecation_deprecate citations: "use citations? instead"

    attr_writer :max_notifications_for_dashboard
    def max_notifications_for_dashboard
      @max_notifications_for_dashboard ||= 5
    end

    attr_writer :activity_to_show_default_seconds_since_now
    def activity_to_show_default_seconds_since_now
      @activity_to_show_default_seconds_since_now ||= 24 * 60 * 60
    end

    attr_writer :arkivo_api
    def arkivo_api?
      @arkivo_api ||= false
    end
    alias arkivo_api arkivo_api?
    deprecation_deprecate arkivo_api: "use arkivo_api? instead"

    def geonames_username=(username)
      Qa::Authorities::Geonames.username = username
    end

    attr_writer :active_deposit_agreement_acceptance
    def active_deposit_agreement_acceptance?
      return true if @active_deposit_agreement_acceptance.nil?
      @active_deposit_agreement_acceptance
    end
    alias active_deposit_agreement_acceptance active_deposit_agreement_acceptance?
    deprecation_deprecate active_deposit_agreement_acceptance: "use active_deposit_agreement_acceptance? instead"

    attr_writer :work_requires_files
    def work_requires_files?
      return true if @work_requires_files.nil?
      @work_requires_files
    end
    alias work_requires_files work_requires_files?
    deprecation_deprecate work_requires_files: "use work_requires_files? instead"

    attr_writer :batch_user_key
    def batch_user_key
      @batch_user_key ||= 'batchuser@example.com'
    end

    attr_writer :audit_user_key
    def audit_user_key
      @audit_user_key ||= 'audituser@example.com'
    end

    # NOTE: This used to be called `working_path` in CurationConcerns
    attr_writer :upload_path
    def upload_path
      @upload_path ||= ->() { Rails.root + 'tmp' + 'uploads' }
    end

    attr_writer :cache_path
    def cache_path
      @cache_path ||= ->() { Rails.root + 'tmp' + 'uploads' + 'cache' }
    end

    # Should a button with "Share my work" show on the front page to all users (even those not logged in)?
    attr_writer :always_display_share_button
    def always_display_share_button?
      return true if @always_display_share_button.nil?
      @always_display_share_button
    end
    alias always_display_share_button always_display_share_button?
    deprecation_deprecate always_display_share_button: "use always_display_share_button? instead"

    attr_writer :google_analytics_id
    def google_analytics_id
      @google_analytics_id ||= nil
    end
    alias google_analytics_id? google_analytics_id

    # Defaulting analytic start date to whenever the file was uploaded by leaving it blank
    attr_writer :analytic_start_date
    attr_reader :analytic_start_date

    attr_writer :permission_levels
    def permission_levels
      @permission_levels ||= { "Choose Access" => "none",
                               "View/Download" => "read",
                               "Edit" => "edit" }
    end

    attr_writer :owner_permission_levels
    def owner_permission_levels
      @owner_permission_levels ||= { "Edit Access" => "edit" }
    end

    attr_writer :translate_uri_to_id
    def translate_uri_to_id
      @translate_uri_to_id ||= ActiveFedora::Noid.config.translate_uri_to_id
    end

    attr_writer :translate_id_to_uri
    def translate_id_to_uri
      @translate_id_to_uri ||= ActiveFedora::Noid.config.translate_id_to_uri
    end

    attr_writer :contact_email
    def contact_email
      @contact_email ||= "repo-admin@example.org"
    end

    attr_writer :subject_prefix
    def subject_prefix
      @subject_prefix ||= "Contact form:"
    end

    attr_writer :model_to_create
    # Returns a lambda that takes a hash of attributes and returns a string of the model
    # name. This is called by the batch upload process
    def model_to_create
      @model_to_create ||= ->(_attributes) { Hyrax.primary_work_type.model_name.name }
    end

    private

      # @param [Symbol, #to_s] model_name - symbol representing the model
      # @return [String] the class name for the model
      def normalize_concern_name(model_name)
        model_name.to_s.camelize
      end
  end
end
