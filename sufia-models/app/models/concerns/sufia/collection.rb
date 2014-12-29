module Sufia
  module Collection
    extend ActiveSupport::Concern
    include Hydra::Collection
    include Sufia::ModelMethods
    include Sufia::Noid
    include Sufia::GenericFile::Permissions

    included do
      before_save :update_permissions
      validates :title, presence: true
    end

    def to_param
      noid
    end

    def update_permissions
      self.visibility = "open"
    end

    # Compute the sum of each file in the collection
    # Return an integer of the result
    def bytes
      members.reduce(0) { |sum, gf| sum + gf.file_size.first.to_i }
    end

    module ClassMethods
      # override the default indexing service
      def indexer
        Sufia::IndexingService
      end
    end

  end
end
