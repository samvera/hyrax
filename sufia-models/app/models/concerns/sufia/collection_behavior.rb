module Sufia
  module CollectionBehavior
    extend ActiveSupport::Concern
    include Hydra::Collection
    include Sufia::ModelMethods
    include Sufia::Noid
    include Sufia::FileSet::Permissions

    included do
      before_save :update_permissions
      validates :title, presence: true
    end

    def update_permissions
      self.visibility = "open"
    end

    # Compute the sum of each file in the collection
    # Return an integer of the result
    def bytes
      members.reduce(0) { |sum, fs| sum + fs.content.size.to_i }
    end
  end
end
