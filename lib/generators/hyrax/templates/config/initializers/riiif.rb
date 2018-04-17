Riiif::Image.file_resolver = Riiif::FedoraHTTPFileResolver.new
Riiif::Image.info_service = lambda do |id, _file|
  # id will look like a path to a pcdm:file
  # (e.g. rv042t299%2Ffiles%2F6d71677a-4f80-42f1-ae58-ed1063fd79c7)
  # but we just want the id for the FileSet it's attached to.

  # Capture everything before the first slash
  fs_id = id.sub(/\A([^\/]*)\/.*/, '\1')
  resp = ActiveFedora::SolrService.get("id:#{fs_id}")
  doc = resp['response']['docs'].first
  raise "Unable to find solr document with id:#{fs_id}" unless doc
  { height: doc['height_is'], width: doc['width_is'] }
end

Riiif::Image.file_resolver.id_to_uri = lambda do |id|
  ActiveFedora::Base.id_to_uri(CGI.unescape(id)).tap do |url|
    Rails.logger.info "Riiif resolved #{id} to #{url}"
  end
end

Riiif::Image.authorization_service = Hyrax::IIIFAuthorizationService

Riiif.not_found_image = Rails.root.join('app', 'assets', 'images', 'us_404.svg')
Riiif.unauthorized_image = Rails.root.join('app', 'assets', 'images', 'us_404.svg')

Riiif::Engine.config.cache_duration_in_days = 365

# HACK WIP make sure that the new file is fetched
# TODO make sure that cached tiles get expired
Riiif::Image.class_eval do
    # @param [String] id The identifier of the file to be looked up.
    # @param [Riiif::File] file Optional: The Riiif::File to use instead of looking one up.
    def initialize(id, passed_file = nil)
      @id = id
      @file = passed_file if passed_file.present?
      Rails.logger.warn "XXXXXXXXXX In Riiif::Image and about to fetch the file! XXXXXXXXXXXXX"
      file
    end
end
