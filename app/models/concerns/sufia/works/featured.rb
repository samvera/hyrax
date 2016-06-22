module Sufia::Works
  module Featured
    extend ActiveSupport::Concern
    included do
      before_destroy :cleanup_featured_works
      after_save :check_featureability
    end

    def cleanup_featured_works
      FeaturedWork.destroy_all(work_id: id)
    end

    def check_featureability
      return unless private?
      cleanup_featured_works if featured?
    end

    def featured?
      return true if FeaturedWork.find_by_work_id(id)
      false
    end
  end
end
