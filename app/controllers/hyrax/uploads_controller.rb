# frozen_string_literal: true
module Hyrax
  ##
  # Receives uploads from the file upload widget, creating and updating
  # {Hyrax::UploadedFile} staging records.
  #
  # The client protocol is two-step: an initial +POST+ carrying only the
  # filename creates the record, then the binary content arrives in one or
  # more requests carrying the record +id+. Requests with a +CONTENT-RANGE+
  # header (+bytes <first>-<last>/<total>+) are chunks of a larger file,
  # uploaded serially, which this controller reassembles server side; that
  # keeps individual requests small enough to pass proxies that cap request
  # size (e.g. Cloudflare's 100 MB limit).
  #
  # How the assembled content is stored depends on
  # {Hyrax::Configuration#uploaded_file_storage_backend}:
  #
  # - +:carrierwave+ appends chunks directly to the CarrierWave-stored file
  #   (the historical behavior; requires local, appendable storage).
  # - +:active_storage+ assembles chunks in a local staging file under
  #   {Hyrax::Configuration#cache_path} and attaches the completed file to
  #   the record's Active Storage attachment when the final chunk arrives,
  #   at which point the configured Active Storage service (local disk, S3,
  #   ...) receives the bytes.
  #
  # @note chunk assembly assumes sequential chunks handled by one node (or
  #   nodes sharing the staging/upload path), the same constraint the
  #   CarrierWave append behavior has always had.
  class UploadsController < ApplicationController
    load_and_authorize_resource class: Hyrax::UploadedFile

    def create
      if params[:id].blank?
        @upload.attributes = { file: params[:files].first,
                               user: current_user }
      else
        upload_with_chunking
      end
      @upload.save!
    end

    def destroy
      @upload.destroy
      head :no_content
    end

    private

    def upload_with_chunking
      @upload = Hyrax::UploadedFile.find(params[:id])
      return upload_with_chunking_active_storage if Hyrax.config.active_storage_uploads?

      upload_with_chunking_carrierwave
    end

    ##
    # @!group CarrierWave backend

    def upload_with_chunking_carrierwave
      unpersisted_upload = Hyrax::UploadedFile.new(file: params[:files].first, user: current_user)
      content_range = request.headers['CONTENT-RANGE']

      if content_range
        handle_chunk(content_range, unpersisted_upload.file)
      else
        @upload.file = unpersisted_upload.file
      end
    end

    def handle_chunk(content_range, chunk)
      file_path = @upload.file.path
      current_size = 0
      File.open(file_path, "r") { |f| current_size = f.size } if file_path && File.exist?(file_path)

      begin_of_chunk = content_range[/\ (.*?)-/, 1].to_i

      if @upload.file.present? && begin_of_chunk == current_size
        File.open(file_path, "ab") do |f|
          f.write(chunk.read)
          f.fsync
        end
      else
        @upload.file = chunk
      end
    end
    # @!endgroup

    ##
    # @!group Active Storage backend

    def upload_with_chunking_active_storage
      chunk = params[:files].first
      content_range = request.headers['CONTENT-RANGE']
      return @upload.store_file(chunk) if content_range.blank?

      handle_chunk_active_storage(content_range, chunk)
    end

    # Chunks are assembled in a local staging file; when the range header
    # shows the final chunk has arrived the assembled file is attached, which
    # uploads it to the configured Active Storage service. A chunk that does
    # not continue the pending assembly restarts assembly with that chunk,
    # mirroring the replacement behavior of the CarrierWave backend.
    def handle_chunk_active_storage(content_range, chunk)
      begin_of_chunk = content_range[/\ (.*?)-/, 1].to_i
      end_of_chunk = content_range[/-(\d+)/, 1].to_i
      total = content_range[%r{/(\d+)}, 1].to_i

      path = staging_path
      current_size = File.exist?(path) ? File.size(path) : 0

      if begin_of_chunk == current_size && current_size.positive?
        File.open(path, 'ab') { |f| append_chunk(f, chunk) }
      else
        FileUtils.mkdir_p(File.dirname(path))
        File.open(path, 'wb') { |f| append_chunk(f, chunk) }
      end

      finalize_staged_file(path) if end_of_chunk + 1 >= total
    end

    def append_chunk(file, chunk)
      file.write(chunk.read)
      file.fsync
    end

    def finalize_staged_file(path)
      File.open(path, 'rb') do |io|
        @upload.store_file(io, filename: @upload.filename)
      end
      File.delete(path)
    end

    ##
    # @return [String] local path where this record's chunks are assembled
    def staging_path
      File.join(Hyrax.config.cache_path.call.to_s, 'chunked_uploads', "#{@upload.id}.part")
    end
    # @!endgroup
  end
end
