# frozen_string_literal: true
require 'hyrax/role_registry'
require 'samvera/nesting_indexer'

module Hyrax
  ##
  # Handles configuration for the Hyrax engine.
  #
  # This class provides a series of accessors for setting and retrieving global
  # engine options. For convenient reference, options are grouped into the
  # following functional areas:
  #
  # - Groups
  # - Identifiers
  # - IIIF
  # - Local Storage
  # - System Dependencies
  # - Theme
  # - Valkyrie
  #
  # == Groups
  #
  # Hyrax has special handling for three groups: "admin", "registered", and "public".
  #
  # These settings support using custom names for these functional groups in
  # object ACLs.
  #
  # == Identifiers
  # == IIIF
  #
  # Objects in Hyrax serve out IIIF manifests. These configuration options
  # toggle server availability, allow customization of image and info URL
  # generation, and provide other hooks for custom IIIF behavior.
  #
  # == Local Storage
  #
  # Hyrax applications need local disk access to store working copies of files
  # for a variety of purposes. Some of these storage paths need to be available
  # all application processes. These options control the paths to use for each
  # type of file.
  #
  # == System Dependiencies
  #
  # @example adding configuration with `Hyrax.config` (recommended usage)
  #
  #   Hyrax.config do |config|
  #     config.work_requires_files = true
  #     config.derivatives_path('tmp/dir/for/derivatives/')
  #   end
  #
  # == Theme
  #
  # Options related to the overall appearance of Hyrax.
  #
  # == Valkyrie
  #
  # *Experimental:* Options for toggling Hyrax's experimental "Wings" valkyrie
  # adapter and configuring valkyrie.
  #
  # @see Hyrax.config
  class Configuration
    include Callbacks

    def initialize
      @registered_concerns = []
      @role_registry = Hyrax::RoleRegistry.new
      @default_active_workflow_name = DEFAULT_ACTIVE_WORKFLOW_NAME
      @nested_relationship_reindexer = default_nested_relationship_reindexer
    end

    DEFAULT_ACTIVE_WORKFLOW_NAME = 'default'
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

    # @!group Analytics

    attr_writer :analytics
    attr_reader :analytics
    def analytics?
      @analytics ||=
        ActiveModel::Type::Boolean.new.cast(ENV.fetch('HYRAX_ANALYTICS', false))
    end

    # Currently supports 'google' or 'matomo'
    # google is default for backward compatability
    attr_writer :analytics_provider
    def analytics_provider
      @analytics_provider ||=
        ENV.fetch('HYRAX_ANALYTICS_PROVIDER', 'google')
    end

    ##
    # @!attribute [w] analytics_start_date
    #   @note this can be set using the +ANALITICS_START_DATE+ environment variable (format is YYYY-MM-DD)
    #   @return [String] date you wish to start collecting analytics for. used to compute the
    #     "all-time" metrics.
    # This is used to compute the "all-time" metrics
    # Set this in your .env file (format is YYYY-MM-DD)
    attr_writer :analytics_start_date
    def analytics_start_date
      @analytics_start_date ||=
        ENV.fetch('ANALYTICS_START_DATE', Time.zone.today - 1.year)
    end

    # Defaulting analytic start date to whenever the file was uploaded by leaving it blank
    attr_writer :analytic_start_date
    attr_reader :analytic_start_date

    ##
    # @deprecated use analytics_id from config/analytics.yml instead
    def google_analytics_id=(value)
      Deprecation.warn("google_analytics_id is deprecated; use analytics_id from config/analytics.yml instead.")
      Hyrax::Analytics.config.analytics_id = value
    end

    ##
    # @deprecated use analytics_id from config/analytics.yml instead
    def google_analytics_id
      Deprecation.warn("google_analytics_id is deprecated; use analytics_id from config/analytics.yml instead.")
      Hyrax::Analytics.config.analytics_id
    end
    alias google_analytics_id? google_analytics_id

    # @!endgroup
    # @!group Groups

    ##
    # @!attribute [w] admin_user_group_name
    #   @return [String]
    # @!attribute [w] public_user_group_name
    #   @return [String]
    # @!attribute [w] registered_user_group_name
    #   @return [String]
    attr_writer :admin_user_group_name
    attr_writer :public_user_group_name
    attr_writer :registered_user_group_name

    ##
    # @api public
    # @return [String]
    def admin_user_group_name
      @admin_user_group_name ||= 'admin'
    end

    ##
    # @api public
    # @return [String]
    def public_user_group_name
      @public_user_group_name ||= 'public'
    end

    ##
    # @api public
    # @return [String]
    def registered_user_group_name
      @registered_user_group_name ||= 'registered'
    end

    # @!endgroup
    # @!group Identifier Minting

    attr_writer :enable_noids
    def enable_noids?
      return @enable_noids unless @enable_noids.nil?
      @enable_noids = true
    end

    attr_writer :noid_template
    def noid_template
      @noid_template ||= '.reeddeeddk'
    end

    attr_writer :noid_minter_class
    def noid_minter_class
      @noid_minter_class ||= ::Noid::Rails::Minter::Db
    end

    attr_writer :minter_statefile
    def minter_statefile
      @minter_statefile ||= '/tmp/minter-state'
    end

    # @!endgroup
    # @!group IIIF

    attr_writer :iiif_image_compliance_level_uri
    attr_writer :iiif_image_server
    attr_writer :iiif_image_size_default
    attr_writer :iiif_image_url_builder
    attr_writer :iiif_info_url_builder
    attr_writer :iiif_metadata_fields
    attr_writer :iiif_manifest_cache_duration
    attr_writer :rendering_predicate

    # Enable IIIF image service. This is required to use the
    # IIIF viewer enabled show page
    #
    # If you have run the hyrax:riiif generator, an embedded riiif service
    # will be used to deliver images via IIIF. If you have not, you will
    # need to configure the following other configuration values to work
    # with your image server.
    #
    # @see Hyrax::Configuration#iiif_image_url_builder
    # @see Hyrax::Configuration#iiif_info_url_builder
    # @see Hyrax::Configuration#iiif_image_compliance_level_uri
    # @see Hyrax::Configuration#iiif_image_size_default
    #
    # @note Default is false
    #
    # @return [Boolean] true to enable, false to disable
    def iiif_image_server?
      return @iiif_image_server unless @iiif_image_server.nil?
      @iiif_image_server = false
    end

    # URL that resolves to an image provided by a IIIF image server
    #
    # @return [#call] lambda/proc that generates a URL to an image
    def iiif_image_url_builder
      @iiif_image_url_builder ||= ->(file_id, base_url, _size, _format) { "#{base_url}/downloads/#{file_id.split('/').first}" }
    end

    # URL that resolves to an info.json file provided by a IIIF image server
    #
    # @return [#call] lambda/proc that generates a URL to image info
    def iiif_info_url_builder
      @iiif_info_url_builder ||= ->(_file_id, _base_url) { '' }
    end

    # URL that indicates your IIIF image server compliance level
    #
    # @return [String] valid IIIF image compliance level URI
    def iiif_image_compliance_level_uri
      @iiif_image_compliance_level_uri ||= 'http://iiif.io/api/image/2/level2.json'
    end

    # IIIF image size default
    #
    # @return [#String] valid IIIF image size parameter
    def iiif_image_size_default
      @iiif_image_size_default ||= '600,'
    end

    # IIIF metadata - fields to display in the metadata section
    #
    # @return [#Array] fields
    def iiif_metadata_fields
      @iiif_metadata_fields ||= Hyrax::Forms::WorkForm.required_fields
    end

    # Duration in which we should cache the generated IIIF manifest.
    # Default is 30 days (in seconds).
    #
    # @return [Integer] number of seconds
    # @see https://api.rubyonrails.org/classes/ActiveSupport/Cache/Store.html#method-i-fetch
    def iiif_manifest_cache_duration
      @iiif_manifest_cache_duration ||= 30.days.to_i
    end

    ##
    # Set predicate for rendering to dc:hasFormat as defined in
    # IIIF Presentation API context:  http://iiif.io/api/presentation/2/context.json
    #
    # @note defaults to dc:hasFormat
    #
    # @return [RDF::URI]
    def rendering_predicate
      @rendering_predicate ||= ::RDF::Vocab::DC.hasFormat
    end

    # @!endgroup
    # @!group Local Storage

    # @!attribute [w] bagit_dir
    #   Location where BagIt files are exported
    attr_writer :bagit_dir
    def bagit_dir
      @bagit_dir ||= "tmp/descriptions"
    end

    # Path on the local file system where derivatives will be stored
    attr_writer :derivatives_path
    def derivatives_path
      @derivatives_path ||= ENV.fetch('HYRAX_DERIVATIVES_PATH', Rails.root.join('tmp', 'derivatives'))
    end

    # Path on the local file system where originals will be staged before being ingested into Fedora.
    attr_writer :working_path
    def working_path
      @working_path ||= ENV.fetch('HYRAX_UPLOAD_PATH', Rails.root.join('tmp', 'uploads'))
    end

    # @todo do we use both upload_path and working path?
    # Path on the local file system where originals will be staged before being ingested into Fedora.
    attr_writer :upload_path
    def upload_path
      @upload_path ||= ->() { ENV.fetch('HYRAX_UPLOAD_PATH') { Rails.root.join('tmp', 'uploads') } }
    end

    attr_writer :cache_path
    def cache_path
      @cache_path ||= ->() { ENV.fetch('HYRAX_CACHE_PATH') { Rails.root.join('tmp', 'cache') } }
    end

    # Path on the local file system where where log and banners will be stored.
    attr_writer :branding_path
    def branding_path
      @branding_path ||= ENV.fetch('HYRAX_BRANDING_PATH', Rails.root.join('public', 'branding'))
    end

    # @!endgroup
    # @!group System Dependencies

    attr_writer :enable_ffmpeg
    def enable_ffmpeg
      return @enable_ffmpeg unless @enable_ffmpeg.nil?
      @enable_ffmpeg = false
    end

    attr_writer :ffmpeg_path
    ##
    # @note we recommend setting the FFMPEG path with the `HYRAX_FFMPEG_PATH`
    #   environment variable
    def ffmpeg_path
      @ffmpeg_path ||= ENV.fetch('HYRAX_FFMPEG_PATH', 'ffmpeg')
    end

    attr_writer :fits_path
    ##
    # @note we recommend setting the FITS path with the `HYRAX_FITS_PATH`
    #   environment variable
    def fits_path
      @fits_path ||= ENV.fetch('HYRAX_FITS_PATH', 'fits.sh')
    end

    attr_writer :fits_message_length
    def fits_message_length
      @fits_message_length ||= 5
    end

    # @!attribute [w] import_export_jar_file_path
    #   Path to the jar file for the Fedora import/export tool
    attr_writer :import_export_jar_file_path
    def import_export_jar_file_path
      @import_export_jar_file_path ||= "tmp/fcrepo-import-export.jar"
    end

    # @!attribute [w] virus_scanner
    #   @return [Hyrax::VirusScanner] the default system virus scanner
    attr_writer :virus_scanner
    def virus_scanner
      @virus_scanner ||=
        if Hyrax.primary_work_type.respond_to?(:default_system_virus_scanner)
          Hyrax.primary_work_type.default_system_virus_scanner
        else
          Hyrax::VirusScanner
        end
    end

    # @!endgroup
    # @!group Theme

    attr_writer :banner_image
    def banner_image
      # This image can be used for free and without attribution. See here for source and license: https://github.com/samvera/hyrax/issues/1551#issuecomment-326624909
      @banner_image ||= 'https://user-images.githubusercontent.com/101482/29949206-ffa60d2c-8e67-11e7-988d-4910b8787d56.jpg'
    end

    ##
    # @return [Boolean]
    def disable_wings
      return @disable_wings unless @disable_wings.nil?
      ActiveModel::Type::Boolean.new.cast(ENV.fetch('HYRAX_SKIP_WINGS', false))
    end
    attr_writer :disable_wings

    attr_writer :display_media_download_link
    # @return [Boolean]
    def display_media_download_link?
      return @display_media_download_link unless @display_media_download_link.nil?
      @display_media_download_link = true
    end

    # @!endgroup
    # @!group Valkyrie

    ##
    # @return [Valkyrie::StorageAdapter]
    def branding_storage_adapter
      @branding_storage_adapter ||= Valkyrie::StorageAdapter.find(:branding_disk)
    end

    ##
    # @param [#to_sym] adapter
    def branding_storage_adapter=(adapter)
      @branding_storage_adapter = Valkyrie::StorageAdapter.find(adapter.to_sym)
    end

    ##
    # @return [Valkyrie::StorageAdapter]
    def derivatives_storage_adapter
      @derivatives_storage_adapter ||= Valkyrie::StorageAdapter.find(:derivatives_disk)
    end

    ##
    # @param [#to_sym] adapter
    def derivatives_storage_adapter=(adapter)
      @derivatives_storage_adapter = Valkyrie::StorageAdapter.find(adapter.to_sym)
    end

    ##
    # @return [#save, #save_all, #delete, #wipe!] an indexing adapter
    def index_adapter
      @index_adapter ||= Valkyrie::IndexingAdapter.find(:null_index)
    end

    ##
    # @param [#to_sym] adapter
    def index_adapter=(adapter)
      @index_adapter = Valkyrie::IndexingAdapter.find(adapter.to_sym)
    end

    ##
    # @return [Boolean] whether to use the experimental valkyrie index
    def query_index_from_valkyrie
      @query_index_from_valkyrie ||= false
    end
    attr_writer :query_index_from_valkyrie

    ##
    # @return [Boolean] whether to use experimental valkyrie storage features
    def use_valkyrie?
      return true if disable_wings # always return true if wings is disabled
      ActiveModel::Type::Boolean.new.cast(ENV.fetch('HYRAX_VALKYRIE', false))
    end
    # @!endgroup

    attr_writer :feature_config_path
    def feature_config_path
      @feature_config_path ||= Rails.root.join('config', 'features.yml')
    end

    attr_accessor :temp_file_base, :enable_local_ingest

    attr_writer :display_microdata
    def display_microdata?
      return @display_microdata unless @display_microdata.nil?
      @display_microdata = true
    end

    attr_writer :microdata_default_type
    def microdata_default_type
      @microdata_default_type ||= 'http://schema.org/CreativeWork'
    end

    attr_writer :fixity_service
    def fixity_service
      @fixity_service ||= Hyrax::Fixity::ActiveFedoraFixityService
    end

    attr_writer :max_days_between_fixity_checks
    def max_days_between_fixity_checks
      @max_days_between_fixity_checks ||= 7
    end

    # Override characterization runner
    attr_accessor :characterization_runner

    ##
    # @!attribute [rw] characterization_service
    #   @return [#run] the service to use for charactaerization for Valkyrie
    #     objects
    #   @ see Hyrax::Characterization::ValkyrieCharacterizationService
    attr_writer :characterization_service
    def characterization_service
      @characterization_service ||=
        Hyrax::Characterization::ValkyrieCharacterizationService
    end

    ##
    # @!attribute [w] characterization_proxy
    #   Which FileSet file to use for mime type resolution
    #   @ see Hyrax::FileSetTypeService
    attr_writer :characterization_proxy
    def characterization_proxy
      @characterization_proxy ||= :original_file
    end

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

    # @deprecated
    def whitelisted_ingest_dirs
      Deprecation.warn(self, "Samvera is deprecating #{self.class}#whitelisted_ingest_dirs " \
        "in Hyrax 3.0. Instead use #{self.class}#registered_ingest_dirs.")
      registered_ingest_dirs
    end

    # @deprecated
    def whitelisted_ingest_dirs=(input)
      Deprecation.warn(self, "Samvera is deprecating #{self.class}#whitelisted_ingest_dirs= " \
        "in Hyrax 3.0. Instead use #{self.class}#registered_ingest_dirs=.")
      self.registered_ingest_dirs = input
    end

    # @!attribute [w] registered_ingest_dirs
    #   List of directories which can be used for local file system ingestion.
    attr_writer :registered_ingest_dirs
    def registered_ingest_dirs
      @registered_ingest_dirs ||= \
        if defined? BrowseEverything
          file_system_dirs = Array.wrap(BrowseEverything.config['file_system'].try(:[], :home)).compact
          # Include the Rails tmp directory for cases where the BrowseEverything provider is required to download the file to a temporary directory first
          tmp_dir = [Rails.root.join('tmp').to_s]
          file_system_dirs + tmp_dir
        else
          []
        end
    end

    callback.enable :after_create_concern, :after_create_fileset,
                    :after_update_content, :after_revert_content,
                    :after_update_metadata, :after_import_local_file_success,
                    :after_import_local_file_failure, :after_fixity_check_failure,
                    :after_destroy, :after_import_url_success,
                    :after_import_url_failure

    # Registers the given curation concern model in the configuration
    # @param [Array<Symbol>,Symbol] curation_concern_types
    def register_curation_concern(*curation_concern_types)
      Array.wrap(curation_concern_types).flatten.compact.each do |cc_type|
        @registered_concerns << cc_type unless @registered_concerns.include?(cc_type)
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

    # A configuration point for changing the behavior of the rights statement service.
    #
    # @!attribute [w] rights_statement_service_class
    #   A configuration point for changing the behavior of the rights statement service.
    #
    #   @see Hyrax::RightsStatementService for implementation details
    attr_writer :rights_statement_service_class
    def rights_statement_service_class
      @rights_statement_service_class ||= Hyrax::RightsStatementService
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

    attr_writer :citations
    def citations?
      @citations ||= false
    end

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

    # rubocop:disable Layout/LineLength
    attr_writer :realtime_notifications
    def realtime_notifications?
      # Coerce @realtime_notifications to false if server software
      # does not support WebSockets, and warn the user that we are
      # overriding the value in0 their config unless it's already
      # flipped to false
      if ENV.fetch('SERVER_SOFTWARE', '').match(/Apache.*Phusion_Passenger/).present?
        Rails.logger.warn('Cannot enable realtime notifications atop Passenger + Apache. Coercing `Hyrax.config.realtime_notifications` to `false`. Set this value to `false` in config/initializers/hyrax.rb to stop seeing this warning.') unless @realtime_notifications == false
        @realtime_notifications = false
      end
      return @realtime_notifications unless @realtime_notifications.nil?
      @realtime_notifications = true
    end
    # rubocop:enable Layout/LineLength

    def geonames_username=(username)
      Qa::Authorities::Geonames.username = username
    end

    attr_writer :active_deposit_agreement_acceptance
    def active_deposit_agreement_acceptance?
      return true if @active_deposit_agreement_acceptance.nil?
      @active_deposit_agreement_acceptance
    end

    attr_writer :admin_set_predicate
    def admin_set_predicate
      @admin_set_predicate ||= ::RDF::Vocab::DC.isPartOf
    end

    attr_writer :work_requires_files
    def work_requires_files?
      return true if @work_requires_files.nil?
      @work_requires_files
    end

    attr_writer :show_work_item_rows
    def show_work_item_rows
      @show_work_item_rows ||= 10 # rows on show view
    end

    # This user is logged as the acting user for jobs and other processes that
    # run without being attributed to a specific user (e.g. creation of the
    # default admin set).
    attr_writer :system_user_key
    def system_user_key
      @system_user_key ||= 'systemuser@example.com'
    end

    attr_writer :batch_user_key
    def batch_user_key
      @batch_user_key ||= 'batchuser@example.com'
    end

    attr_writer :audit_user_key
    def audit_user_key
      @audit_user_key ||= 'audituser@example.com'
    end

    attr_writer :collection_type_index_field
    def collection_type_index_field
      @collection_type_index_field ||= 'collection_type_gid_ssim'
    end

    attr_writer :collection_model
    ##
    # @return [#constantize] a string representation of the collection
    #   model
    def collection_model
      @collection_model ||= '::Collection'
    end

    ##
    # @return [Class] the configured collection model class
    def collection_class
      collection_model.safe_constantize
    end

    attr_writer :admin_set_model
    ##
    # @return [#constantize] a string representation of the admin set
    #   model
    def admin_set_model
      @admin_set_model ||= 'AdminSet'
    end

    ##
    # @return [Class] the configured admin set model class
    def admin_set_class
      admin_set_model.constantize
    end

    ##
    # @return [String] the default admin set id
    def default_admin_set_id
      default_admin_set.id.to_s
    end

    ##
    # @return [Hyrax::AdministrativeSet] the default admin set
    # @see Hyrax::AdminSetCreateService.find_or_create_default_admin_set
    def default_admin_set
      @default_admin_set ||= Hyrax::AdminSetCreateService.find_or_create_default_admin_set
    end

    ##
    # If the default admin set is changed, call reset.  The next time one of the default
    # admin set configs is checked, the default_admin_set variable will be updated.
    # @see Hyrax::DefaultAdministrativeSet.update
    def reset_default_admin_set
      @default_admin_set = nil
    end

    attr_writer :id_field
    def id_field
      @id_field || index_field_mapper.id_field
    end

    attr_writer :index_field_mapper
    def index_field_mapper
      @index_field_mapper ||= ActiveFedora.index_field_mapper
    end

    # Should a button with "Share my work" show on the front page to users who are not logged in?
    attr_writer :display_share_button_when_not_logged_in
    def display_share_button_when_not_logged_in?
      return true if @display_share_button_when_not_logged_in.nil?
      @display_share_button_when_not_logged_in
    end

    attr_writer :permission_levels
    def permission_levels
      @permission_levels ||= { I18n.t('hyrax.permission_levels.read') => "read",
                               I18n.t('hyrax.permission_levels.edit') => "edit" }
    end

    attr_writer :owner_permission_levels
    def owner_permission_levels
      @owner_permission_levels ||= { I18n.t('hyrax.permission_levels.owner.edit') => "edit" }
    end

    attr_writer :permission_options
    def permission_options
      @permission_options ||= { I18n.t('hyrax.permission_levels.options.none') => "none",
                                I18n.t('hyrax.permission_levels.options.read') => "read",
                                I18n.t('hyrax.permission_levels.options.edit') => "edit" }
    end

    attr_writer :publisher
    def publisher
      @publisher ||= Hyrax::Publisher.instance
    end

    attr_writer :translate_uri_to_id

    def translate_uri_to_id
      @translate_uri_to_id ||=
        begin
          baseparts = 2 + [(::Noid::Rails.config.template.gsub(/\.[rsz]/, '').length.to_f / 2).ceil, 4].min

          lambda do |uri|
            uri.to_s.split(ActiveFedora.fedora.base_path).last.split('/', baseparts).last
          end
        end
    end

    attr_writer :translate_id_to_uri
    def translate_id_to_uri
      @translate_id_to_uri ||= lambda do |id|
        "#{ActiveFedora.fedora.host}#{ActiveFedora.fedora.base_path}/#{::Noid::Rails.treeify(id)}"
      end
    end

    attr_writer :resource_id_to_uri_transformer
    def resource_id_to_uri_transformer
      Deprecation.warn('Use Hyrax.config.translate_uri_to_id instead.')

      @resource_id_to_uri_transformer ||= lambda do |resource, base_url|
        file_id = CGI.escape(resource.file_identifier.to_s)
        fs_id = CGI.escape(resource.file_set_id.to_s)
        "#{base_url}#{::Noid::Rails.treeify(fs_id)}/files/#{file_id}"
      end
    end

    attr_writer :contact_email
    def contact_email
      @contact_email ||= "repo-admin@example.org"
    end

    attr_writer :subject_prefix
    def subject_prefix
      @subject_prefix ||= "Contact form:"
    end

    attr_writer :extract_full_text
    def extract_full_text?
      return @extract_full_text unless @extract_full_text.nil?
      @extract_full_text = true
    end

    attr_writer :uploader
    def uploader
      @uploader ||= if Rails.env.development?
                      # use sequential uploads in development to avoid database locking problems with sqlite3.
                      default_uploader_config.merge(limitConcurrentUploads: 1, sequentialUploads: true)
                    else
                      default_uploader_config
                    end
    end

    attr_accessor :nested_relationship_reindexer

    def default_nested_relationship_reindexer
      ->(id:, extent:) { Samvera::NestingIndexer.reindex_relationships(id: id, extent: extent) }
    end

    attr_writer :solr_select_path
    def solr_select_path
      @solr_select_path ||= ActiveFedora.solr_config.fetch(:select_path, 'select')
    end

    attr_writer :identifier_registrars
    def identifier_registrars
      @identifier_registrars ||= {}
    end

    # A configuration point for changing the available range for
    # selecting per page results
    #
    # @!attribute [w] range_for_number_of_results_to_display_per_page
    #   A configuration point for changing the available range for
    #   selecting per page results
    # @note This has no impact on the default page size of the controller.
    attr_writer :range_for_number_of_results_to_display_per_page

    # @return [Array<Integer>]
    def range_for_number_of_results_to_display_per_page
      @range_for_number_of_results_to_display_per_page ||= [10, 20, 50, 100]
    end

    private

    # @param [Symbol, #to_s] model_name - symbol representing the model
    # @return [String] the class name for the model
    def normalize_concern_name(model_name)
      model_name.to_s.camelize
    end

    # @return [Hash] config options for the uploader
    def default_uploader_config
      {
        limitConcurrentUploads: 6,
        maxNumberOfFiles: 100,
        maxFileSize: 500.megabytes
      }
    end
  end
end
