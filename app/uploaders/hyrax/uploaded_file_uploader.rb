# frozen_string_literal: true
module Hyrax
  class UploadedFileUploader < CarrierWave::Uploader::Base
    # Override the directory where uploaded files will be stored.
    # This is a sensible default for uploaders that are meant to be mounted:
    def store_dir
      (configured_upload_path / model.class.to_s.underscore / mounted_as.to_s / model.id.to_s).to_s
    end

    def cache_dir
      (configured_cache_path / model.class.to_s.underscore / mounted_as.to_s / model.id.to_s).to_s
    end

    private

    def configured_upload_path
      Pathname.new(Hyrax.config.upload_path.call)
    end

    def configured_cache_path
      Pathname.new(Hyrax.config.cache_path.call)
    end
  end
end
