module Sufia
  class UploadedFileUploader < CarrierWave::Uploader::Base
    # Override the directory where uploaded files will be stored.
    # This is a sensible default for uploaders that are meant to be mounted:
    def store_dir
      base_path + "#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
    end

    private

      def base_path
        Sufia.config.upload_path.call
      end
  end
end
