module Hyrax::Works
  module Trophies
    extend ActiveSupport::Concern
    included do
      before_destroy :cleanup_trophies
    end

    def cleanup_trophies
      Trophy.where(work_id: id).destroy_all
    end
  end
end
