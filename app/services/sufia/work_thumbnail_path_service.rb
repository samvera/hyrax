module Sufia
  class WorkThumbnailPathService < CurationConcerns::ThumbnailPathService
    class << self
      def default_image
        ActionController::Base.helpers.image_path 'work.png'
      end
    end
  end
end
