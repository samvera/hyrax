require 'hyrax/callbacks'
require 'hyrax/role_registry'
require 'samvera/nesting_indexer'

module Hyrax
  class Configuration
    include Callbacks

    def initialize
      @registered_concerns = []
      @role_registry = Hyrax::RoleRegistry.new
      @default_active_workflow_name = DEFAULT_ACTIVE_WORKFLOW_NAME
      @nested_relationship_reindexer = default_nested_relationship_reindexer
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

    # Path on the local file system where where log and banners will be stored.
    attr_writer :branding_path
    def branding_path
      @branding_path ||= Rails.root.join('public', 'branding')
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

    attr_writer :max_days_between_fixity_checks
    def max_days_between_fixity_checks
      @max_days_between_fixity_checks ||= 7
    end

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

    attr_writer :display_media_download_link
    def display_media_download_link?
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

    # @!attribute [w] bagit_dir
    #   Location where BagIt files are exported
    attr_writer :bagit_dir
    def bagit_dir
      @bagit_dir ||= "tmp/descriptions"
    end

    # @!attribute [w] whitelisted_ingest_dirs
    #   List of directories which can be used for local file system ingestion.
    attr_writer :whitelisted_ingest_dirs
    def whitelisted_ingest_dirs
      @whitelisted_ingest_dirs ||= \
        if defined? BrowseEverything
          Array.wrap(BrowseEverything.config['file_system'].try(:[], :home)).compact
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

    # The MetadataAdapter to use when persisting resources with Valkyrie
    #
    # @see lib/wings
    # @see https://github.com/samvera-labs/valkyrie
    def valkyrie_metadata_adapter
      Valkyrie::MetadataAdapter.find(@valkyrie_metadata_adapter || :wings_adapter)
    end

    def valkyrie_metadata_adapter=(adapter)
      raise StandardError, "Hyrax currently only supports :wings_adapter as the configured valkyrie_metadata_adapter." unless adapter == :wings_adapter
      @valkyrie_metadata_adapter = adapter
    end

    # The StorageAdapter to use when persisting resources with Valkyrie
    #
    # @see lib/wings
    # @see https://github.com/samvera-labs/valkyrie
    def valkyrie_storage_adapter
      Valkyrie::StorageAdapter.find(@valkyrie_storage_adapter || :fedora)
    end
    attr_writer :valkyrie_storage_adapter

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

    attr_writer :banner_image
    def banner_image
      # This image can be used for free and without attribution. See here for source and license: https://github.com/samvera/hyrax/issues/1551#issuecomment-326624909
      @banner_image ||= 'https://user-images.githubusercontent.com/101482/29949206-ffa60d2c-8e67-11e7-988d-4910b8787d56.jpg'
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

    attr_writer :analytics
    attr_reader :analytics
    def analytics?
      @analytics ||= false
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

    # rubocop:disable Metrics/LineLength
    attr_writer :realtime_notifications
    def realtime_notifications?
      # Coerce @realtime_notifications to false if server software
      # does not support WebSockets, and warn the user that we are
      # overriding the value in their config unless it's already
      # flipped to false
      if ENV.fetch('SERVER_SOFTWARE', '').match(/Apache.*Phusion_Passenger/).present?
        Rails.logger.warn('Cannot enable realtime notifications atop Passenger + Apache. Coercing `Hyrax.config.realtime_notifications` to `false`. Set this value to `false` in config/initializers/hyrax.rb to stop seeing this warning.') unless @realtime_notifications == false
        @realtime_notifications = false
      end
      return @realtime_notifications unless @realtime_notifications.nil?
      @realtime_notifications = true
    end
    # rubocop:enable Metrics/LineLength

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

    # Set predicate for rendering to dc:hasFormat as defined in
    #   IIIF Presentation API context:  http://iiif.io/api/presentation/2/context.json
    attr_writer :rendering_predicate
    def rendering_predicate
      @rendering_predicate ||= ::RDF::Vocab::DC.hasFormat
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

    # Enable IIIF image service. This is required to use the
    # IIIF viewer enabled show page
    #
    # If you have run the hyrax:riiif generator, an embedded riiif service
    # will be used to deliver images via IIIF. If you have not, you will
    # need to configure the following other configuration values to work
    # with your image server.
    #
    # @see config.iiif_image_url_builder
    # @see config.iiif_info_url_builder
    # @see config.iiif_image_compliance_level_uri
    # @see config.iiif_image_size_default
    #
    # @note Default is false
    #
    # @return [Boolean] true to enable, false to disable
    def iiif_image_server?
      return @iiif_image_server unless @iiif_image_server.nil?
      @iiif_image_server = false
    end
    attr_writer :iiif_image_server

    # URL that resolves to an image provided by a IIIF image server
    #
    # @return [#call] lambda/proc that generates a URL to an image
    def iiif_image_url_builder
      @iiif_image_url_builder ||= ->(file_id, base_url, _size, _format) { "#{base_url}/downloads/#{file_id.split('/').first}" }
    end
    attr_writer :iiif_image_url_builder

    # URL that resolves to an info.json file provided by a IIIF image server
    #
    # @return [#call] lambda/proc that generates a URL to image info
    def iiif_info_url_builder
      @iiif_info_url_builder ||= ->(_file_id, _base_url) { '' }
    end
    attr_writer :iiif_info_url_builder

    # URL that indicates your IIIF image server compliance level
    #
    # @return [String] valid IIIF image compliance level URI
    def iiif_image_compliance_level_uri
      @iiif_image_compliance_level_uri ||= 'http://iiif.io/api/image/2/level2.json'
    end
    attr_writer :iiif_image_compliance_level_uri

    # IIIF image size default
    #
    # @return [#String] valid IIIF image size parameter
    def iiif_image_size_default
      @iiif_image_size_default ||= '600,'
    end
    attr_writer :iiif_image_size_default

    # IIIF metadata - fields to display in the metadata section
    #
    # @return [#Array] fields
    def iiif_metadata_fields
      @iiif_metadata_fields ||= Hyrax::Forms::WorkForm.required_fields
    end
    attr_writer :iiif_metadata_fields

    # Should a button with "Share my work" show on the front page to users who are not logged in?
    attr_writer :display_share_button_when_not_logged_in
    def display_share_button_when_not_logged_in?
      return true if @display_share_button_when_not_logged_in.nil?
      @display_share_button_when_not_logged_in
    end

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
      @permission_levels ||= { "View/Download" => "read",
                               "Edit access" => "edit" }
    end

    attr_writer :owner_permission_levels
    def owner_permission_levels
      @owner_permission_levels ||= { "Edit access" => "edit" }
    end

    attr_writer :permission_options
    def permission_options
      @permission_options ||= { "Choose Access" => "none",
                                "View/Download" => "read",
                                "Edit" => "edit" }
    end

    attr_writer :translate_uri_to_id

    def translate_uri_to_id
      @translate_uri_to_id ||= lambda do |uri|
        baseparts = 2 + [(::Noid::Rails.config.template.gsub(/\.[rsz]/, '').length.to_f / 2).ceil, 4].min
        uri.to_s.sub("#{ActiveFedora.fedora.host}#{ActiveFedora.fedora.base_path}", '').split('/', baseparts).last
      end
    end

    attr_writer :translate_id_to_uri
    def translate_id_to_uri
      @translate_id_to_uri ||= lambda do |id|
        "#{ActiveFedora.fedora.host}#{ActiveFedora.fedora.base_path}/#{::Noid::Rails.treeify(id)}"
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
