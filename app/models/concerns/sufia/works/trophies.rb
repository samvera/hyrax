module Sufia::Works
  module Trophies
    extend ActiveSupport::Concern
    included do
      before_destroy :cleanup_trophies
    end

    def cleanup_trophies
      Trophy.destroy_all(work_id: id)
    end
  end
end
