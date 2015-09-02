module CurationConcerns
  module IndexesThumbnails
    extend ActiveSupport::Concern

    included do
      class_attribute :thumbnail_path_service
      self.thumbnail_path_service = ThumbnailPathService
    end

    def thumbnail_path
      self.class.thumbnail_path_service.call(object)
    end
  end
end
