CurationConcerns.configure do |config|
  # Should schema.org microdata be displayed?
  # config.display_microdata = true

  # What default microdata type should be used if a more appropriate
  # type can not be found in the locale file?
  # config.microdata_default_type = 'http://schema.org/CreativeWork'

  # How frequently should a file be audited.
  # Note: In CurationConcerns you must trigger the FileSetAuditService manually.
  # config.max_days_between_audits = 7

  # Enable displaying usage statistics in the UI
  # Requires a Google Analytics id and OAuth2 keyfile.  See README for more info
  # config.analytics = false

  # Specify a date you wish to start collecting Google Analytic statistics for.
  # config.analytic_start_date = DateTime.new(2014,9,10)

  # Where to store tempfiles, leave blank for the system temp directory (e.g. /tmp)
  # config.temp_file_base = '/home/developer1'

  # Location on local file system where derivatives will be stored.
  # If you use a multi-server architecture, this MUST be a shared volume.
  # config.derivatives_path = File.join(Rails.root, 'tmp', 'derivatives')

  # Location on local file system where uploaded files will be staged
  # prior to being ingested into the repository or having derivatives generated.
  # If you use a multi-server architecture, this MUST be a shared volume.
  # config.working_path = File.join(Rails.root, 'tmp', 'uploads')

  # If you have ffmpeg installed and want to transcode audio and video uncomment this line
  # config.enable_ffmpeg = true

  # CurationConcerns uses NOIDs for files and collections instead of Fedora UUIDs
  # where NOID = 10-character string and UUID = 32-character string w/ hyphens
  # config.enable_noids = true

  # Specify a different template for your repository's NOID IDs
  # config.noid_template = ".reeddeeddk"

  # Store identifier minter's state in a file for later replayability
  # If you use a multi-server architecture, this MUST be on a shared volume.
  # config.minter_statefile = '/tmp/minter-state'

  # Specify whether the media display partial should render a download link
  # config.display_media_download_link = true

  # Specify the path to the file characterization tool:
  # config.fits_path = "fits.sh"

  # Specify a date you wish to start collecting Google Analytic statistics for.
  # Leaving it blank will set the start date to when ever the file was uploaded by
  # NOTE: if you have always sent analytics to GA for downloads and page views leave this commented out
  # config.analytic_start_date = DateTime.new(2014,9,10)

  # Fedora import/export tool
  #
  # Path to the Fedora import export tool jar file
  # config.import_export_jar_file_path = "tmp/fcrepo-import-export.jar"
  #
  # Location where descriptive rdf should be exported
  # config.descriptions_directory = "tmp/descriptions"
  #
  # Location where binaries are exported
  # config.binaries_directory "tmp/binaries"

  # To configure the Administration Dashboard to contain additional
  #  menu items and corresponding actions uncomment the block below
  #  and add in you new actions.
  # See the CurationConcerns wiki for more information
  #
  # config.dashboard_configuration = {
  #       menu: {
  #           index: {},
  #           resource_details: {}
  #       },
  #       actions: {
  #           index: {
  #               partials: [
  #                   "total_objects_charts",
  #                   "total_embargo_visibility"
  #               ]
  #           },
  #           resource_details: {
  #               partials: [
  #                   "total_objects"
  #               ]
  #           }
  #       },
  #       data_sources: {
  #           resource_stats: CurationConcerns::ResourceStatisticsSource
  #       }
  #   }
end

Date::DATE_FORMATS[:standard] = '%m/%d/%Y'
