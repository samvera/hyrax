CurationConcerns.configure do |config|
  config.resource_types = {
    'Article' => 'Article',
    'Audio' => 'Audio',
    'Book' => 'Book',
    'Capstone Project' => 'Capstone Project',
    'Conference Proceeding' => 'Conference Proceeding',
    'Dataset' => 'Dataset',
    'Dissertation' => 'Dissertation',
    'Image' => 'Image',
    'Journal' => 'Journal',
    'Map or Cartographic Material' => 'Map or Cartographic Material',
    'Masters Thesis' => 'Masters Thesis',
    'Part of Book' => 'Part of Book',
    'Poster' => 'Poster',
    'Presentation' => 'Presentation',
    'Project' => 'Project',
    'Report' => 'Report',
    'Research Paper' => 'Research Paper',
    'Software or Program Code' => 'Software or Program Code',
    'Video' => 'Video',
    'Other' => 'Other'
  }

  # Should schema.org microdata be displayed?
  # config.display_microdata = true

  config.microdata_default_type = 'http://schema.org/CreativeWork'

  config.resource_types_to_schema = config.resource_types.map do |k, v|
    [k, I18n.t("curation_concerns.schema_org.resource_type.#{v}", default: config.microdata_default_type)]
  end.to_h

  # How frequently should a file be audited.
  # Note: In CurationConcerns you must trigger the FileSetAuditService manually.
  # config.max_days_between_audits = 7

  # Enable displaying usage statistics in the UI
  # Requires a Google Analytics id and OAuth2 keyfile.  See README for more info
  # config.analytics = false

  # Specify a Google Analytics tracking ID to gather usage statistics
  # config.google_analytics_id = 'UA-99999999-1'

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

  # Specify the prefix for Redis keys:
  # config.redis_namespace = "curation_concerns"

  # Specify the path to the file characterization tool:
  # config.fits_path = "fits.sh"

  # Specify a date you wish to start collecting Google Analytic statistics for.
  # Leaving it blank will set the start date to when ever the file was uploaded by
  # NOTE: if you have always sent analytics to GA for downloads and page views leave this commented out
  # config.analytic_start_date = DateTime.new(2014,9,10)
end

Date::DATE_FORMATS[:standard] = '%m/%d/%Y'
