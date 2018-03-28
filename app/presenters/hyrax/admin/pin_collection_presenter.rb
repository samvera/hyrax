module Hyrax
  module Admin
    class PinCollectionPresenter

      def initialize(params)
        @params = params
      end

      def pin_collection
        pinned = PinnedCollection.find_or_initialize_by(:user_id => @params[:user_id], :collection => @params[:collection])
        pinned.update_attributes({ :pinned => @params[:status] })
      end

      def all_pinned_collections
        PinnedCollection.where(:user_id => @params[:user_id], :pinned => 1)
      end
    end
  end
end
