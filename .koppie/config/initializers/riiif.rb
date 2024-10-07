# frozen_string_literal: true
Rails.application.reloader.to_prepare do
  Riiif::Image.info_service = lambda do |id, _file|
    # id will look like a path to a pcdm:file
    # (e.g. rv042t299%2Ffiles%2F6d71677a-4f80-42f1-ae58-ed1063fd79c7)
    # but we just want the id for the FileSet it's attached to.

    fs_id = id.sub(/\A([^\/]*)\/.*/, '\1')
    resp = Hyrax::SolrService.get("id:#{fs_id}")
    doc = resp['response']['docs'].first
    raise "Unable to find solr document with id:#{fs_id}" unless doc
    { height: doc['height_is'], width: doc['width_is'], format: doc['mime_type_ssi'], channels: doc['alpha_channels_ssi'] }
  end

  if Hyrax.config.use_valkyrie?
    Riiif::Image.file_resolver = Hyrax::RiiifFileResolver.new
  else
    Riiif::Image.file_resolver = Riiif::HttpFileResolver.new

    Riiif::Image.file_resolver.id_to_uri = lambda do |id|
      Hyrax::Base.id_to_uri(CGI.unescape(id)).tap do |url|
        Rails.logger.info "Riiif resolved #{id} to #{url}"
      end
    end
  end

  Riiif::Image.authorization_service = Hyrax::IiifAuthorizationService

  Riiif.not_found_image = Rails.root.join('app', 'assets', 'images', 'us_404.svg')
  Riiif.unauthorized_image = Rails.root.join('app', 'assets', 'images', 'us_404.svg')

  Riiif::Engine.config.cache_duration = 1.day
end

module Hyrax
  # Adds file locking to Riiif::File
  # @see RiiifFileResolver
  Rails.application.reloader.to_prepare do
    class RiiifFile < Riiif::File
      include ActiveSupport::Benchmarkable

      attr_reader :id
      def initialize(input_path, tempfile = nil, id:)
        super(input_path, tempfile)
        raise(ArgumentError, "must specify id") if id.blank?
        @id = id
      end

      # Wrap extract in a read lock and benchmark it
      def extract(transformation, image_info = nil)
        Riiif::Image.file_resolver.file_locks[id].with_read_lock do
          benchmark "RiiifFile extracted #{path} with #{transformation.to_params}", level: :debug do
            super
          end
        end
      end

      private

      def logger
        Hyrax.logger
      end
    end
  end


  class RiiifFileResolver
    include ActiveSupport::Benchmarkable

    # @param [String] id from iiif manifest
    # @return [Riiif::File]
    def find(id)
      path = nil
      file_locks[id].with_write_lock do
        path = build_path(id)
        path = build_path(id, force: true) unless File.exist?(path) # Ensures the file is locally available
      end
      RiiifFile.new(path, id: id)
    end

    # tracks individual file locks
    # @see RiiifFile
    # @return [Concurrent::Map<Concurrent::ReadWriteLock>]
    def file_locks
      @file_locks ||= Concurrent::Map.new do |k, v|
        k.compute_if_absent(v) { Concurrent::ReadWriteLock.new }
      end
    end

    private

    def build_path(id, force: false)
      Riiif::Image.cache.fetch("riiif:" + Digest::MD5.hexdigest("path:#{id}"),
                               expires_in: Riiif::Image.expires_in,
                               force: force) do
        load_file(id)
      end
    end

    def load_file(id)
      benchmark "RiiifFileResolver loaded #{id}", level: :debug do
        fs_id = id.sub(/\A([^\/]*)\/.*/, '\1')
        file_set = Hyrax.query_service.find_by(id: fs_id)
        file_metadata = Hyrax.custom_queries.find_original_file(file_set: file_set)
        file_metadata.file.disk_path.to_s # Stores a local copy in tmpdir
      end
    end

    def logger
      Hyrax.logger
    end
  end
end

