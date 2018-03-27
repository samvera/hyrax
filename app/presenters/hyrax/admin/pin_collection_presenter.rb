module Hyrax
  module Admin
    class PinCollectionPresenter

      def initialize(params)
        @params = params
      end

      def pinned_collections()
        PinnedCollection.find_or_create_by({user_id: @params[:user_id], collection: @params[:collection]})
            .update_attributes({pinned: @params[:status]})
      end
    end
  end
end
