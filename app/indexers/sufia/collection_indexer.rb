# frozen_string_literal: true
module Sufia
  class CollectionIndexer < CurationConcerns::CollectionIndexer
    self.thumbnail_path_service = Sufia::CollectionThumbnailPathService
  end
end
