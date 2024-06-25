# frozen_string_literal: true
Hyrax.config do |config|
  # Hyrax can integrate with Zotero's Arkivo service for automatic deposit
  # of Zotero-managed research items.
  # Defaults to false.  See README for more info
  config.arkivo_api = true

  config.analytics = ActiveModel::Type::Boolean.new.cast(ENV.fetch('HYRAX_ANALYTICS', 'false'))
  config.analytics_provider = ENV.fetch('HYRAX_ANALYTICS_PROVIDER', 'google')
  # Injected via `rails g hyrax:work GenericWork`
  config.register_curation_concern :generic_work
  # Injected via `rails g hyrax:work NamespacedWorks::NestedWork`
  config.register_curation_concern :"namespaced_works/nested_work"
  # Injected via `rails g hyrax:work_resource Monograph`
  config.register_curation_concern :monograph
  # Injected via `rails g hyrax:work_resource GenericWorkResource`
  # config.register_curation_concern :generic_work_resource

  config.iiif_image_server = true
  config.work_requires_files = false
  config.citations = true

  config.characterization_options = { ch12n_tool: ENV.fetch('CH12N_TOOL', 'fits').to_sym }

  # Returns a URL that resolves to an image provided by a IIIF image server
  config.iiif_image_url_builder = lambda do |file_id, base_url, size, format|
    Riiif::Engine.routes.url_helpers.image_url(file_id, host: base_url, size: size)
  end

  # Returns a URL that resolves to an info.json file provided by a IIIF image server
  config.iiif_info_url_builder = lambda do |file_id, base_url|
    uri = Riiif::Engine.routes.url_helpers.info_url(file_id, host: base_url)
    uri.sub(%r{/info\.json\Z}, '')
  end

  # If browse-everything has been configured, load the configs.  Otherwise, set to nil.
  begin
    if defined? BrowseEverything
      config.browse_everything = BrowseEverything.config
    else
      Rails.logger.warn "BrowseEverything is not installed"
    end
  rescue Errno::ENOENT
    config.browse_everything = nil
  end

  config.geonames_username = ENV['GEONAMES_USERNAME'] || ''

  ##
  # Set the system-wide virus scanner
  config.virus_scanner = Hyrax::VirusScanner

  # The default method used for Solr queries. Values are :get or :post.
  # Post is suggested to prevent issues with URL length.
  config.solr_default_method = :post

  ##
  # To index to the Valkyrie core, uncomment the following lines.
  # config.query_index_from_valkyrie = true
  # config.index_adapter = :solr_index

  ##
  # NOTE: To Valkyrie works, use Monograph which is_a Hyrax::Work is_a Valkyrie::Resource
  # To use Valkyrie models, uncomment the following lines.
  # config.collection_model = 'Hyrax::PcdmCollection' # collection without basic metadata
  # config.collection_model = 'CollectionResource'    # collection with basic metadata
  # config.admin_set_model = 'Hyrax::AdministrativeSet'

  # dassie needs legacy AF models
  # If using Frayja/Frigg then use the resource they provide
  if Hyrax.config.valkyrie_transition?
    config.collection_model = 'CollectionResource'
    config.admin_set_model = 'AdminSetResource'
    config.file_set_model = 'Hyrax::FileSet'
  else
    # dassie needs legacy AF models
    config.collection_model = '::Collection'
    config.admin_set_model = 'AdminSet'
    config.file_set_model = '::FileSet'
  end
end

Date::DATE_FORMATS[:standard] = "%m/%d/%Y"

Qa::Authorities::Local.register_subauthority('subjects', 'Qa::Authorities::Local::TableBasedAuthority')
Qa::Authorities::Local.register_subauthority('languages', 'Qa::Authorities::Local::TableBasedAuthority')
Qa::Authorities::Local.register_subauthority('genres', 'Qa::Authorities::Local::TableBasedAuthority')
